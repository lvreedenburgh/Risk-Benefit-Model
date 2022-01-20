breed [consumers consumer]
breed [farmers farmer]

turtles-own [
  clustered?
  ;in_network?
  leader?
  in_conversation?
  influence

  ; calculate the weight the agent gives to external factor
  weight_knowledge_dev
  weight_trust_government
  weight_trust_agriculture ; consumers only
  weight_regulations
  weight_water_demand ; farmers only
  weight_rainfall ; farmers only
  weight_GDP ; farmers only

;  ; assign high, medium, low priority for agent on this external factor
;  himedlow_knowledge_dev
;  himedlow_trust_government
;  himedlow_trust_agriculture ; consumers only
;  himedlow_regulations
;  himedlow_water_demand ; farmers only
;  himedlow_rainfall ; farmers only: high rainfall means they are less concerned about having droughts, whereas low means they are very concerned about having droughts.
;  himedlow_GDP ; farmers only

  conversation_partner
  leader_in_network?
  new_risk
  new_benefit
]
consumers-own [
  cluster ; in which cluster is consumer
  network ; list of consumers in network
  network_size ; size of network

  risk
  benefit
]

farmers-own [
  cluster ; in which cluster is farmer
  network ; list of farmers in network
  network_size ; size of network

  risk
  benefit
]

globals[
  Avg_risk ; average risk perception of consumers
  Avg_benefit ; average benefit perception of consumers

  ;consumers_total ; amount consumers
  ;farmers_total ; amount farmers
  ;optimistic_consumers ; amount
  ;neutral_consumers ; amount
  ;alarmed_consumers ; amount
  ;conflicted_consumers ; amount
  ;optimistic_farmers ; amount
  ;neutral_farmers ; amount
  ;alarmed_farmers ; amount
  ;conflicted_farmers ; amount

  max_network_size ; number
  cluster_list
  agentset
  ext_factors_list
  ext_change_list
  ext_rate_list

  optimistic_%_farmer
  neutral_%_farmer
  alarmed_%_farmer
  conflicted_%_farmer

  optimistic_%_consumer
  neutral_%_consumer
  alarmed_%_consumer
  conflicted_%_consumer

  optimistic_%
  neutral_%
  alarmed_%
  conflicted_%

  TIME
]

to setup
  clear-all
  reset-ticks

  set max_network_size 6 ; network does not include agent themselves, so they have 6 agents in their network max
  set cluster_list ["optimistic" "neutral" "alarmed" "conflicted"]


  setuppatches
  setupconsumers
  setupfarmers

end

to setuppatches
  ask patches [
    ifelse pxcor < 35 and pycor >= 45
    [set pcolor green]
    [ifelse pxcor < 45 and pycor < 45
      [set pcolor black]
      [ifelse pxcor >= 45 and pycor < 35
        [set pcolor red]
        [set pcolor orange]
      ]
    ]
  ]

end

to setupconsumers

  set optimistic_%_consumer 0.252
  set neutral_%_consumer 0.396
  set alarmed_%_consumer 0.118
  set conflicted_%_consumer 0.234

  create-consumers No_consumers [
    set color white
    set shape "person"
    set size 3
    set network []
    set influence 1
    assign-weights
  ]

  set agentset consumers
  assigntoclusters

  ask consumers [set leader? false]
  ask n-of (consumer_leaders * No_consumers) consumers with [leader? = false] [set leader? true set size 5 set influence leader_influence]

  ask agentset [
    if leader? = true [
      setupnetworks_leaders
    ]
  ]

  ask agentset [if leader? = false [
    setupnetworks_rest
    ]
  ]
end

to setupfarmers

  set optimistic_%_farmer 0.28
  set neutral_%_farmer 0.648
  set alarmed_%_farmer 0.022
  set conflicted_%_farmer 0.05

  create-farmers No_farmers [
    set color yellow
    set shape "person"
    set size 3
    set network []
    set influence 1
    assign-weights
  ]

  set agentset farmers
  assigntoclusters

  ask farmers [set leader? false]
  ask n-of (farmer_leaders * No_farmers) farmers with [leader? = false] [set leader? true set size 5 set influence leader_influence]

  ask agentset [
    if leader? = true [
      setupnetworks_leaders
    ]
  ]

  ask agentset [if leader? = false [
    setupnetworks_rest
    ]
  ]

end

to assigntoclusters

  if agentset = consumers [
    set optimistic_% optimistic_%_consumer
    set neutral_% neutral_%_consumer
    set alarmed_% alarmed_%_consumer
    set conflicted_% conflicted_%_consumer
  ]

  if agentset = farmers [
    set optimistic_% optimistic_%_farmer
    set neutral_% neutral_%_farmer
    set alarmed_% alarmed_%_farmer
    set conflicted_% conflicted_%_farmer
  ]

  ask agentset [set clustered? 0]


  ask n-of (floor (optimistic_% * count agentset)) agentset with [clustered? = 0] [ set cluster "optimistic" set clustered? 1]
  ask n-of (floor (neutral_% * count agentset)) agentset with [clustered? = 0] [ set cluster "neutral" set clustered? 1]
  ask n-of (floor (alarmed_% * count agentset)) agentset with [clustered? = 0] [ set cluster "alarmed" set clustered? 1]
  ask n-of (floor (conflicted_% * count agentset)) agentset with [clustered? = 0] [ set cluster "conflicted" set clustered? 1]



  let optimistic_rest ((optimistic_% * count agentset) - floor (optimistic_% * count agentset))
  let neutral_rest ((neutral_% * count agentset) - floor (neutral_% * count agentset))
  let alarmed_rest ((alarmed_% * count agentset) - floor (alarmed_% * count agentset))
  let conficted_rest ((conflicted_% * count agentset) - floor (conflicted_% * count agentset))

;  if debug? [
;    print optimistic_rest
;    print neutral_rest
;    print alarmed_rest
;    print conficted_rest
;  ]
  let rest_list sort-by > (list optimistic_rest neutral_rest alarmed_rest conficted_rest)
;  if debug? [show rest_list]

; TO DO: check whether can be optimized and optimize
  if any? agentset with [clustered? = 0][
    ifelse first rest_list = optimistic_rest [
      ask one-of agentset with [clustered? = 0] [set cluster "optimistic" set clustered? 1]
    ][
      ifelse first rest_list = neutral_rest[
        ask one-of agentset with [clustered? = 0] [set cluster "neutral" set clustered? 1]
      ][
        ifelse first rest_list = alarmed_rest[
          ask one-of agentset with [clustered? = 0] [set cluster "alarmed" set clustered? 1]
        ][
          if first rest_list = conficted_rest[
            ask one-of agentset with [clustered? = 0] [set cluster "conflicted" set clustered? 1]
          ]
        ]
      ]
    ]
  ]


  if any? agentset with [clustered? = 0][
    ifelse item 2 rest_list = optimistic_rest [
      ask one-of agentset with [clustered? = 0] [set cluster "optimistic" set clustered? 1]
    ][
      ifelse item 2 rest_list = neutral_rest[
        ask one-of agentset with [clustered? = 0] [set cluster "neutral" set clustered? 1]
      ][
        ifelse item 2 rest_list = alarmed_rest[
          ask one-of agentset with [clustered? = 0] [set cluster "alarmed" set clustered? 1]
        ][
          if item 2 rest_list = conficted_rest[
            ask one-of agentset with [clustered? = 0] [set cluster "conflicted" set clustered? 1]
          ]
        ]
      ]
    ]
  ]


  if any? agentset with [clustered? = 0][
    ifelse item 3 rest_list = optimistic_rest [
      ask one-of agentset with [clustered? = 0] [set cluster "optimistic" set clustered? 1]
    ][
      ifelse item 3 rest_list = neutral_rest[
        ask one-of agentset with [clustered? = 0] [set cluster "neutral" set clustered? 1]
      ][
        ifelse item 3 rest_list = alarmed_rest[
          ask one-of agentset with [clustered? = 0] [set cluster "alarmed" set clustered? 1]
        ][
          if item 3 rest_list = conficted_rest[
            ask one-of agentset with [clustered? = 0] [set cluster "conflicted" set clustered? 1]
          ]
        ]
      ]
    ]
  ]

  if any? agentset with [clustered? = 0][
    ifelse item 4 rest_list = optimistic_rest [
      ask one-of agentset with [clustered? = 0] [set cluster "optimistic" set clustered? 1]
    ][
      ifelse item 4 rest_list = neutral_rest[
        ask one-of agentset with [clustered? = 0] [set cluster "neutral" set clustered? 1]
      ][
        ifelse item 4 rest_list = alarmed_rest[
          ask one-of agentset with [clustered? = 0] [set cluster "alarmed" set clustered? 1]
        ][
          if item 4 rest_list = conficted_rest[
            ask one-of agentset with [clustered? = 0] [set cluster "conflicted" set clustered? 1]
          ]
        ]
      ]
    ]
  ]

  ask agentset with [cluster = "optimistic"] [set new_risk random-normal 24.3 7.1 set new_benefit random-normal 57.7 6.5 setRandB new_risk new_benefit]
  ask agentset with [cluster = "neutral"] [set new_risk random-normal 36.1 6.5 set new_benefit random-normal 39.1 7.0 setRandB new_risk new_benefit]
  ask agentset with [cluster = "alarmed"] [set new_risk random-normal 55.2 7.8 set new_benefit random-normal 26.5 8.8 setRandB new_risk new_benefit]
  ask agentset with [cluster = "conflicted"] [set new_risk random-normal 46.3 7.1 set new_benefit random-normal 48.8 6.8 setRandB new_risk new_benefit]

  ask agentset [setxy risk benefit]
end

to assign-weights
  ; low = (0> x >1) * external factor
  ; medium = 1/external factor
  ; high = (1> x >=2) * external factor

  ; first assign hi-med-low-external-factor

  let highrandom (random-float 100 )

  ifelse highrandom < 13 [
    set weight_knowledge_dev (1 + random-float 1)
    ]
    [ifelse random-float 100 > 74 [
      set weight_knowledge_dev (random-float 1)
    ]
      [set weight_knowledge_dev 0]]

  ifelse highrandom < 5.6 [
   set weight_water_demand (1 + random-float 1)
  ]
  [ ifelse random-float 100 > 45 [
    set weight_water_demand (random-float 1)
    ]
    [ set weight_water_demand 0
  ]]

  ;; Education level is taken as GDP as  there is a lot of research clearly linking the education expenditure of a country to GDP.
  ifelse highrandom < 22 [
   set weight_GDP (1 + random-float 1)
  ]
  [ ifelse random-float 100 > 96.3 [
    set weight_GDP (random-float 1)
    ]
    [ set weight_GDP 0
  ]]


  ;;; Doubting whether this needs to have a low and high or just leave it at it is.
  ifelse highrandom < 29 [
    set weight_rainfall (1 + random-float 1)
  ]
  [set weight_rainfall 0]

  ifelse highrandom > 75 [
     set weight_regulations (random-float 1)
  ]
  [ set weight_regulations 0]

  ifelse highrandom < 5 [
    set weight_trust_government (1 + random-float 1)
  ]
  [ set weight_trust_government 0]

  ifelse highrandom < 58 [
    set weight_trust_agriculture (1 + random-float 1)
  ]
  [ set weight_trust_agriculture 0]



;  ; calculate the weight
;  set weight_knowledge_dev (himedlow_knowledge_dev * knowledge_dev)
;  set weight_water_demand (himedlow_water_demand * water_demand)
;  set weight_rainfall (himedlow_rainfall * rainfall)
;  set weight_regulations (himedlow_regulations * regulations)
;  set weight_trust_government (himedlow_trust_government * trust_government)



end


to setupnetworks_leaders

  let potential_members agentset with [leader? = false and network_size < max_network_size and link-with myself = nobody]; leaders cannot take leaders to their network

  while [network_size < Leader_network_size and any? potential_members] ;by that we ensure that each leader will ends up with the maximum network and thus cannot be taken in the network of normal agent in the next phase
  [ ;print network_size
    let potential_members_same_cluster potential_members with [leader? = false and network_size < max_network_size and cluster = [cluster] of self]
    let potential_members_different_cluster potential_members with [leader? = false and network_size < max_network_size and cluster != [cluster] of self]
    let new_member_same_cluster one-of other potential_members_same_cluster
    let new_member_different_cluster one-of other potential_members_different_cluster
    ;first we take an agent leader's cluster
    if new_member_same_cluster != nobody [
      ask new_member_same_cluster [
        create-link-with myself
        set network lput myself network
        set network_size network_size + 1
        set leader_in_network? true
      ]
      set network lput new_member_same_cluster network
      set network_size network_size + 1
    ]
    ;next step is to take an agent from one of teh different clusters. It is omitted if the network size is achieved in previous phase
    if new_member_different_cluster != nobody and network_size < Leader_network_size [
      ask new_member_different_cluster [
        create-link-with myself
        set network lput myself network
        set network_size network_size + 1
        set leader_in_network? true
      ]
      set network lput new_member_different_cluster network
      set network_size network_size + 1
    ]
    set potential_members other potential_members with [leader? = false and network_size < max_network_size and link-with myself = nobody]
  ]


  if debug? [
    print self
    print network_size
    print sort network
  ]


end

to setupnetworks_rest

  let potential_members agentset with [leader? = false and network_size < max_network_size and link-with myself = nobody]; leaders cannot be taken a sthey already created full networks

  while [network_size < max_network_size and any? potential_members]
    [
      ;if debug? [print potential_members]

    let potential_members_same_cluster potential_members with [cluster = [cluster] of self]
    let potential_members_different_cluster potential_members with [cluster != [cluster] of self]
    let new_member_same_cluster one-of other potential_members_same_cluster
    let new_member_different_cluster one-of other potential_members_different_cluster
    ;first we take an agent leader's cluster
    if new_member_same_cluster != nobody [
      ask new_member_same_cluster [
        create-link-with myself
        set network lput myself network
        set network_size network_size + 1
        set leader_in_network? true
      ]
      set network lput new_member_same_cluster network
      set network_size network_size + 1
    ]
    ;next step is to take an agent from one of teh different clusters. It is omitted if the network size is achieved in previous phase
    if new_member_different_cluster != nobody and network_size < max_network_size [
      ask new_member_different_cluster [
        create-link-with myself
        set network lput myself network
        set network_size network_size + 1
        set leader_in_network? true
      ]
      set network lput new_member_different_cluster network
      set network_size network_size + 1
    ]
    set potential_members other potential_members with [leader? = false and network_size < max_network_size and link-with myself = nobody]

      if debug? [print network]
  ]
; if debug? [
;    print self
;    print network_size
;    print sort network
; ]


end

to go

  ask turtles [set in_conversation? false]
  consumers-risk-benefit
  farmers-risk-benefit
  scenarios
  tick
  set TIME ticks
end

to consumers-risk-benefit
  ; Let all consumers change their r and b based on external factors before they start communicating with eachother
  ask consumers [change-R-and-B] ; do first the leaders need to update this? It includes external factors & changing r and b

  set agentset consumers
  leaders-pick
;  setup-external-factors
  pick

end

to farmers-risk-benefit
  ask farmers [change-R-and-B] ; do first the leaders need to update this?

  set agentset farmers
  leaders-pick
;  setup-external-factors
  pick

end

to leaders-pick

  ask agentset with [leader? = true and in_conversation? = false]
  [
    ; pick a random (?) number of agents from your network
    set conversation_partner nobody
    let chance random 6
    let temp_cluster_list remove [cluster] of self cluster_list

    if debug? [
      print "I am a leader!"
      print self
      print chance
      print [cluster] of self
      print temp_cluster_list
    ]


    set conversation_partner one-of (turtle-set network) with [in_conversation? = false and leader? = false]

    ; if chance is 0, 1 or 2, pick consumer from own cluster
    ;ifelse chance < 3
     ; [set conversation_partner one-of other agentset with [ cluster = [cluster] of self and in_conversation? = false and leader? = false]]
      ; elif chance is 3 pick consumer from other cluster at position 0 of clusterlist without own cluster in it
      ;[ifelse chance = 3
       ; [set conversation_partner one-of agentset with [ cluster = item 0 temp_cluster_list and in_conversation? = false and leader? = false]]
        ; elif chance is 4 pick consumer from other cluster at position 1 of clusterlist without own cluster in it
        ;[ifelse chance = 4
         ; [set conversation_partner one-of agentset with [ cluster = item 1 temp_cluster_list and in_conversation? = false and leader? = false]]
          ; else pick consumer from other cluster at position 2 of clusterlist without own cluster in it
          ;[set conversation_partner one-of agentset with [ cluster = item 2 temp_cluster_list and in_conversation? = false and leader? = false]]
      ;]
    ;]

    if debug? [print conversation_partner]

    set in_conversation? true
    if conversation_partner != nobody [
      ask conversation_partner [set in_conversation? true set conversation_partner myself]
      conversation self conversation_partner
    ]

  ]

end

to pick
  ask agentset with [leader? = false and in_conversation? = false]
  [
    ; pick a random (?) number of agents from your network
    set conversation_partner nobody
    let chance random 6
    let temp_cluster_list remove [cluster] of self cluster_list


    if debug? [
      print chance
      print [cluster] of self
      print temp_cluster_list
      print self
    ]

    set conversation_partner one-of (turtle-set network) with [in_conversation? = false and leader? = false]

    ; if chance is 0, 1 or 3, pick consumer from own cluster
    ;ifelse chance < 3
     ; [set conversation_partner one-of other agentset with [ cluster = [cluster] of self and in_conversation? = false]]
      ; elif chance is 3 pick consumer from other cluster at position 0 of clusterlist without own cluster in it
      ;[ifelse chance = 3
       ; [set conversation_partner one-of agentset with [ cluster = item 0 temp_cluster_list and in_conversation? = false]]
        ; elif chance is 4 pick consumer from other cluster at position 1 of clusterlist without own cluster in it
        ;[ifelse chance = 4
         ; [set conversation_partner one-of agentset with [ cluster = item 1 temp_cluster_list and in_conversation? = false]]
          ; else pick consumer from other cluster at position 2 of clusterlist without own cluster in it
          ;[set conversation_partner one-of agentset with [ cluster = item 2 temp_cluster_list and in_conversation? = false]]
      ;]
    ;]

    ; the last consumers that get to pick often return nobody, because the consumers from the cluster they picked are already taken
    if debug? [print conversation_partner]

    set in_conversation? true
    if conversation_partner != nobody [
      ask conversation_partner [set in_conversation? true set conversation_partner myself]
      conversation self conversation_partner
    ]

  ]

end



to change-R-and-B ; change the risk and benefit for the consumer or farmer
;; adding some explanation per factor why there is a plus or a minus


;; If there is a high knowledge development (>1) the risk is lower and benefit higher.
;; if there is a low knowledge development (<1) the risk is higher and the benefit lower.
  ifelse weight_knowledge_dev > 1 ; knowledge reuse project and insufficient information in the paper
  [set risk (risk - weight_knowledge_dev * knowledge_dev)
   set benefit (benefit + weight_knowledge_dev * knowledge_dev)
  ]
  [set risk (risk + weight_knowledge_dev * knowledge_dev)
   set benefit (benefit - weight_knowledge_dev * knowledge_dev)
  ]

;; high trust = low risk
  ifelse weight_trust_government > 1
  [set risk (risk - weight_trust_government * trust_government)]
  [set risk (risk + weight_trust_government * trust_government)]

;; high perceived control = low risk (vice versa)
  ifelse weight_regulations < 1 ; perceived control in the paper
  [set risk (risk + weight_regulations * regulations)]
  [set risk (risk - weight_regulations * regulations) ]

;; If there is a high water demand, there is a higher benefit and lower perceived risk (the benefit is assumed)
;; If there is a low water demand, there is a higer perceived risk and lower benefit (the benefit is assumed)
  if is-farmer? true [
    ifelse weight_water_demand < 1
    [set benefit (benefit - weight_water_demand * water_demand)
      set risk (risk + weight_water_demand * water_demand)
    ]
    [ set benefit (benefit + weight_water_demand * water_demand)
      set risk (risk - weight_water_demand * water_demand)]

    ifelse weight_GDP < 1
    [set risk (risk + weight_GDP * GDP) ]
    [set benefit (benefit + weight_GDP * GDP) ]

;; if there is a high confidence rainfall will be enough, there is a lower perceived risk
    ifelse weight_rainfall > 1 ; drought experience in the paper
    [set risk (risk - weight_rainfall * rainfall)]
    [set risk (risk + weight_rainfall * rainfall)]

  ]

  if is-consumer? true [
    ifelse weight_trust_agriculture > 1
    [set risk (risk - weight_trust_agriculture * trust_agriculture)]
    [set risk (risk + weight_trust_agriculture * trust_agriculture)]
  ]





end

to conversation [person1 person2]
  ; calculate
;  if debug? [
;    print "person1"
;    print person1
;    print "risk of person1"
;    print [risk] of person1
;    print "benefit of person1"
;    print [benefit] of person1
;    print "person2"
;    print person2
;    print "risk of person2"
;    print [risk] of person2
;    print "benefit of person2"
;    print [benefit] of person2
;  ]

  ; Calculate the risk level of the conversation
  let avg_conversation_risk ((([risk] of person1 * [influence] of person1) + ([risk] of person2 * [influence] of person2)) / ([influence] of person1 + [influence] of person2))

  ; Calculate the benefit level of the conversation
  let avg_conversation_benefit ((([benefit] of person1 * [influence] of person1) + ([benefit] of person2 * [influence] of person2)) / ([influence] of person1 + [influence] of person2))

  ; If two agents differ from each other on the risk benefit spectrum, they influence each other less
  let D sqrt abs(([risk] of person1 - [risk] of person2) ^ 2 + ([benefit] of person1 - [benefit] of person2) ^ 2)
  let F ([influence] of person1 + [influence] of person2) + 2 * (D / 98.994949) ; Dmax =98.994949 = sqrt abs((70-0) ^ 2 + (70-0) ^ 2)

;  if debug? [
;    print "D"
;    print D
;    print "F"
;    print F
;    print "avg conversation_risk"
;    print avg_conversation_risk
;    print "avg_conversation benefit"
;    print avg_conversation_benefit
;  ]

  ask person1 [
   set new_risk ([risk] of person1 - (([risk] of person1 - avg_conversation_risk) / F))
   set new_benefit ([benefit] of person1 - (([benefit] of person1 - avg_conversation_benefit) / F))
   setRandB new_risk new_benefit
   changecluster
   setxy risk benefit]

  ask person2 [
   set new_risk ([risk] of person2 - (([risk] of person2 - avg_conversation_risk) / F))
   set new_benefit ([benefit] of person2 - (([benefit] of person2 - avg_conversation_benefit) / F))
   setRandB new_risk new_benefit
   changecluster
   setxy risk benefit]
end


to changecluster
;  if debug? [
;    print "my old cluster is"
;    print cluster
;  ]

  ifelse risk < 35 and benefit > 45
    [set cluster "optimistic"]
    [ifelse risk < 45 and benefit < 45
      [set cluster "neutral"]
      [ifelse risk > 45 and benefit < 35
        [set cluster "alarmed"]
        [set cluster "conflicted"]
      ]
    ]

;  if debug? [
;    print "my new cluster is"
;    print cluster
;  ]
end

to setRandB [temp_risk temp_benefit]
  ifelse 0 < temp_risk and temp_risk < 70
    [set risk temp_risk]
    [ifelse temp_risk > 70
      [set risk 70]
      [set risk 0]
    ]

  if debug? [
      print "new risk"
      print risk
    ]

  ifelse 0 < temp_benefit and temp_benefit < 70
    [set benefit temp_benefit]
    [ifelse temp_benefit > 70
      [set benefit 70]
      [set benefit 0]
    ]
;  if debug? [
;      print "new benefit"
;      print benefit
;    ]
end

to scenarios
  ; get new values for external factors lists,
  set ext_factors_list (list GDP rainfall water_demand regulations trust_agriculture trust_government knowledge_dev)
  set ext_change_list (list GDP_change rainfall_change w_demand_change regulations_change trust_agri_change trust_gov_change know_dev_change)
  set ext_rate_list (list GDP_change_r rainfall_change_r w_demand_change_r regulations_change_r trust_agri_change_r trust_gov_change_r know_dev_change_r)

  ; create iterator
  let i 0
  foreach ext_factors_list [
    [x] ->

;    if debug? [
;      print x
;      print item i ext_change_list
;      print item i ext_rate_list
;    ]

    ; change the values of ext_factors_list accordingly
    ifelse item i ext_change_list = "decreasing"
      [ifelse item i ext_rate_list = "gradual"
        [set ext_factors_list replace-item i ext_factors_list max (list 0 (x - 0.001))]
        [ifelse item i ext_rate_list = "medium"
          [set ext_factors_list replace-item i ext_factors_list max (list 0 (x - 0.002))]
          [set ext_factors_list replace-item i ext_factors_list max (list 0 (x - random-float 0.005))] ; temporary
        ]
    ]
      [if item i ext_change_list = "increasing"
        [ifelse item i ext_rate_list = "gradual"
          [set ext_factors_list replace-item i ext_factors_list min (list 10 (x + 0.001))]
          [ifelse item i ext_rate_list = "medium"
           [set ext_factors_list replace-item i ext_factors_list min (list 10 (x + 0.002))]
           [set ext_factors_list replace-item i ext_factors_list min (list 10 (x + random-float 0.005))] ; temporary
          ]
        ]
      ]

    set i i + 1
  ]

;  if debug? [
;      print ext_factors_list ]

  ; update the actual external factors, looks a bit ugly, but works
  set GDP item 0 ext_factors_list
  set rainfall item 1 ext_factors_list
  set water_demand item 2 ext_factors_list
  set regulations item 3 ext_factors_list
  set trust_agriculture item 4 ext_factors_list
  set trust_government item 5 ext_factors_list
  set knowledge_dev item 6 ext_factors_list

end

to basevalues
  set GDP 5
  set rainfall 5
  set water_demand 5
  set regulations 5
  set trust_agriculture 5
  set trust_government 5
  set knowledge_dev 5
end


to customvalues
  set GDP custom_GDP
  set rainfall custom_rainfall
  set water_demand custom_w_demand
  set regulations custom_regulations
  set trust_agriculture custom_trust_agri
  set trust_government custom_trust_gov
  set knowledge_dev custom_know_dev
end

; Consumer reporters
to-report average_risk_consumers
  report mean [risk] of consumers
end

to-report average_benefit_consumers
  report mean [benefit] of consumers
end



to-report optimistic_consumers
  report count consumers with [cluster = "optimistic"]
end

to-report conflicted_consumers
  report count consumers with [cluster = "conflicted"]
end

to-report neutral_consumers
  report count consumers with [cluster = "neutral"]
end

to-report alarmed_consumers
  report count consumers with [cluster = "alarmed"]
end


; Farmer reporters
to-report average_risk_farmers
  report mean [risk] of farmers
end

to-report average_benefit_farmers
  report mean [benefit] of farmers
end

to-report optimistic_farmers
  report count farmers with [cluster = "optimistic"]
end

to-report conflicted_farmers
  report count farmers with [cluster = "conflicted"]
end

to-report neutral_farmers
  report count farmers with [cluster = "neutral"]
end

to-report alarmed_farmers
  report count farmers with [cluster = "alarmed"]
end
@#$#@#$#@
GRAPHICS-WINDOW
647
10
1152
516
-1
-1
7.0
1
10
1
1
1
0
0
0
1
0
70
0
70
0
0
1
ticks
30.0

BUTTON
36
10
99
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
101
45
176
78
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
36
45
99
78
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
24
622
196
655
consumer_leaders
consumer_leaders
0
0.25
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
23
662
195
695
farmer_leaders
farmer_leaders
0
0.25
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
27
702
199
735
leader_influence
leader_influence
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
26
493
198
526
No_consumers
No_consumers
4
100
28.0
4
1
NIL
HORIZONTAL

SLIDER
26
526
198
559
No_farmers
No_farmers
4
20
8.0
4
1
NIL
HORIZONTAL

SWITCH
213
487
316
520
debug?
debug?
1
1
-1000

SLIDER
26
559
198
592
Leader_network_size
Leader_network_size
6
12
6.0
1
1
NIL
HORIZONTAL

SLIDER
36
96
208
129
GDP
GDP
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
36
142
208
175
rainfall
rainfall
1
10
2.895999999999788
1
1
NIL
HORIZONTAL

SLIDER
36
185
208
218
water_demand
water_demand
1
10
9.208000000000073
1
1
NIL
HORIZONTAL

SLIDER
36
230
208
263
regulations
regulations
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
36
275
208
308
trust_agriculture
trust_agriculture
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
37
317
209
350
trust_government
trust_government
1
10
10.0
1
1
NIL
HORIZONTAL

CHOOSER
208
96
346
141
GDP_change
GDP_change
"decreasing" "constant" "increasing"
2

CHOOSER
345
96
483
141
GDP_change_r
GDP_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
208
141
346
186
rainfall_change
rainfall_change
"decreasing" "constant" "increasing"
0

CHOOSER
346
141
485
186
rainfall_change_r
rainfall_change_r
"gradual" "medium" "abrupt"
0

CHOOSER
208
230
346
275
regulations_change
regulations_change
"decreasing" "constant" "increasing"
2

CHOOSER
208
274
346
319
trust_agri_change
trust_agri_change
"decreasing" "constant" "increasing"
2

CHOOSER
207
186
345
231
w_demand_change
w_demand_change
"decreasing" "constant" "increasing"
2

CHOOSER
345
186
488
231
w_demand_change_r
w_demand_change_r
"gradual" "medium" "abrupt"
1

CHOOSER
346
230
490
275
regulations_change_r
regulations_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
346
274
484
319
trust_agri_change_r
trust_agri_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
208
318
346
363
trust_gov_change
trust_gov_change
"decreasing" "constant" "increasing"
2

CHOOSER
346
319
484
364
trust_gov_change_r
trust_gov_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
209
363
347
408
know_dev_change
know_dev_change
"decreasing" "constant" "increasing"
2

CHOOSER
347
363
487
408
know_dev_change_r
know_dev_change_r
"gradual" "medium" "abrupt"
2

SLIDER
37
361
209
394
knowledge_dev
knowledge_dev
1
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
211
47
320
80
Base Values
basevalues
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
483
96
638
156
custom_GDP
10.0
1
0
Number

INPUTBOX
483
156
638
216
custom_rainfall
10.0
1
0
Number

INPUTBOX
483
215
638
275
custom_w_demand
10.0
1
0
Number

INPUTBOX
484
275
639
335
custom_regulations
10.0
1
0
Number

INPUTBOX
485
336
640
396
custom_trust_agri
10.0
1
0
Number

INPUTBOX
485
397
640
457
custom_trust_gov
10.0
1
0
Number

INPUTBOX
486
458
641
518
custom_know_dev
10.0
1
0
Number

BUTTON
348
47
460
80
Custom Values
customvalues
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1189
14
1332
59
Average risk of consumers
average_risk_consumers
2
1
11

MONITOR
1331
14
1495
59
Average benefit of consumers
average_benefit_consumers
2
1
11

MONITOR
1189
58
1332
103
Average risk of farmers
average_risk_farmers
2
1
11

MONITOR
1331
58
1495
103
Average benefit of farmers
average_benefit_farmers
2
1
11

PLOT
1189
104
1633
310
Consumer clusters
Weeks
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Optimistic consumers" 1.0 0 -10899396 true "" "plotxy ticks optimistic_consumers"
"Conflicted consumers" 1.0 0 -955883 true "" "plotxy ticks conflicted_consumers"
"Neutral consumers" 1.0 0 -16777216 true "" "plotxy ticks neutral_consumers"
"Alarmed consumers" 1.0 0 -2674135 true "" "plotxy ticks alarmed_consumers"

PLOT
1189
310
1634
516
Farmer clusters
Weeks
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Optimistic farmers" 1.0 0 -10899396 true "" "plotxy ticks optimistic_farmers"
"Conflicted farmers" 1.0 0 -955883 true "" "plotxy ticks conflicted_farmers"
"Neutral farmer" 1.0 0 -16777216 true "" "plotxy ticks neutral_farmers"
"Alarmed farmers" 1.0 0 -2674135 true "" "plotxy ticks alarmed_farmers"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@