breed [consumers consumer]
breed [farmers farmer]

turtles-own [
  clustered? ; is turtle already clustered?
  leader? ; is tutrtle a leader?
  in_conversation? ; is turtle already in conversation?
  influence ; influence of normal turtle

  ; weight the agent gives to external factor
  weight_knowledge_dev
  weight_trust_government
  weight_regulations

  conversation_partner ; who is the turtle in conversation with?
  leader_in_network? ; is there a leader in the turtles network
  risk ; risk of turtle
  benefit ; benefit of turtle
  new_risk ; what will be the risk after changes
  new_benefit l; what will be the benefit after changes
]
consumers-own [
  cluster ; in which cluster is consumer
  network ; list of consumers in network
  network_size ; size of network
  weight_trust_agriculture ; consumer only
]

farmers-own [
  cluster ; in which cluster is farmer
  network ; list of farmers in network
  network_size ; size of network
  weight_water_demand ; farmers only
  weight_rainfall ; farmers only
  weight_GDP ; farmers only
]

globals[
  max_network_size ; number
  cluster_list ; list of the clusters
  agentset
  ext_factors_list ; list of external factors
  ext_change_list ; list of the external factor change directions
  ext_rate_list ; list of external factor change rates

  optimistic_%_farmer ; percentage of optimistic farmers at tick 0
  neutral_%_farmer ; percentage of neutral farmers at tick 0
  alarmed_%_farmer ; percentage of alarmed farmers at tick 0
  conflicted_%_farmer ; percentage of conflicted farmers at tick 0

  optimistic_%_consumer ; percentage of optimistic consumers at tick 0
  neutral_%_consumer ; percentage of neutral consumers at tick 0
  alarmed_%_consumer ; percentage of alarmed consumers at tick 0
  conflicted_%_consumer ; percentage of conflicted consumers at tick 0

  optimistic_% ; generic percentage optimistic for procedure
  neutral_% ; generic percentage neutral for procedure
  alarmed_% ; generic percentage alarmed for procedure
  conflicted_% ; generic percentage conflicted for procedure

  TIME ; time of the run, necessary for EMA workbench
  talk_consumers ; counter for when consumers talk to eachother
  frequency_talk_consumers ; frequency how often consumers talk to eachother
  talk_farmers ; counter for when farmers talk to eachother
  frequency_talk_farmers ; frequency how often farmers talk to eachother

  ; calibration globals
  max_reinforcement ; maximum change due to own reinforcing beliefs
  conversation_calibration
  gradual_change ; how much an external factor changes because of gradual change
  medium_change ; how much an external factor changes because of medium change
  max_abrupt_change ; how much an external factor maximally changes because of medium change

  run_seed ; for debugging


]

to setup
  clear-all
  reset-ticks
  set run_seed new-seed ; get a random seed to use for our run
  ;print run_seed
  random-seed run_seed


  basevalues
  set max_network_size 6 ; network does not include agent themselves, so they have 6 agents in their network max
  set cluster_list ["optimistic" "neutral" "alarmed" "conflicted"]


  ; calibtrated values
  ; How many weeks are between turtles talking to each other?
  set frequency_talk_consumers 4
  set frequency_talk_farmers 4
  ; Start counter at 0
  set talk_consumers 0
  set talk_farmers 0

  set max_reinforcement 0.05
  set conversation_calibration 10
  set gradual_change 0.001
  set medium_change 0.002
  set max_abrupt_change 0.005


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
  ; Distribution derived from literature
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
  ; Distribution derived from literature
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

  ; For every weight a new grouping% is created
  ; Values for thresholds of groups taken from several papers
  let grouping% (random-float 100 )

  ifelse grouping% < 13
    [set weight_knowledge_dev (random-float 0.5 + 0.5)]
    [ifelse grouping% > 74
      [set weight_knowledge_dev (0.1 + random-float 0.4)]
      [set weight_knowledge_dev 0]]

  set grouping% (random-float 100 )

  ifelse grouping% > 75
    [set weight_regulations (random-float 0.5 + 0.5)]
    [set weight_regulations (0.01 + random-float 0.49)]

  set grouping% (random-float 100 )

  ifelse grouping% < 5
    [set weight_trust_government (random-float 0.5 + 0.5)]
    [set weight_trust_government 0]

  ; Only farmers have these weights
  if is-farmer? self [

    set grouping% (random-float 100 )

    ifelse grouping% < 5.6
     [set weight_water_demand (random-float 0.5 + 0.5)]
     [ifelse grouping% > 45
      [set weight_water_demand (0.1 + random-float 0.4)]
      [set weight_water_demand (0.01 + random-float 0.1)]
     ]

    set grouping% (random-float 100 )


    ifelse grouping% < 22
      [set weight_GDP (random-float 0.5 + 0.5)]
      [ifelse grouping% > 96.3
        [set weight_GDP (0.1 + random-float 0.4)]
        [set weight_GDP (0.01 + random-float 0.1)]
      ]

    set grouping% (random-float 100 )

    ifelse grouping% < 29
    [set weight_rainfall (random-float 0.5 + 0.5)]
    [set weight_rainfall (0.01 + random-float 0.49)]

  ]

  ; Only consumers have this weight
  if is-consumer? self [
    set grouping% (random-float 100 )

    ifelse grouping% < 58 [
      set weight_trust_agriculture (random-float 0.5 + 0.5)
    ]
    [ set weight_trust_agriculture 0]
  ]





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

  ifelse TIME < 1560 ;assumption: a year have 52 weeks, simulation stops at the endof year 30
  [
    ask turtles [set in_conversation? false]
    consumers-risk-benefit
    farmers-risk-benefit
    scenarios
    tick
    set TIME ticks
  ][
    stop
  ]
end

to consumers-risk-benefit
  ; Let all consumers change their r and b based on external factors before they start communicating with eachother
  ask consumers [make-up-own-opinion] ; make-up-own-opinion


  set agentset consumers


  if talk_consumers = frequency_talk_consumers [

    leaders-pick
;  setup-external-factors
    pick
    set talk_consumers 0
  ]
  set talk_consumers talk_consumers + 1

end

to farmers-risk-benefit
  ask farmers [make-up-own-opinion] ;

  set agentset farmers


  if talk_farmers = frequency_talk_farmers [

    leaders-pick
;  setup-external-factors
    pick
    set talk_farmers 0
  ]
  set talk_farmers talk_farmers + 1

end

to leaders-pick

  ask agentset with [leader? = true and in_conversation? = false]
  [

    set conversation_partner nobody


    if debug? [
      print "I am a leader!"
      print self
      print [cluster] of self
    ]


    set conversation_partner one-of (turtle-set network) with [in_conversation? = false and leader? = false]

    ; Structural change of picking another turtle to talk to, leave it in commented, might be useful in the future for structural analysis

    ;let chance random 6
    ;let temp_cluster_list remove [cluster] of self cluster_list


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



    if debug? [
      print [cluster] of self
      print self
    ]

    set conversation_partner one-of (turtle-set network) with [in_conversation? = false and leader? = false]

    ; Structural change of picking another turtle to talk to, leave it in commented, might be useful in the future for structural analysis

    ;let chance random 6
    ;let temp_cluster_list remove [cluster] of self cluster_list

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



to make-up-own-opinion ; turtles creates its own opinion


  if debug? [
    print "old"
    print risk
    print benefit]

  ; Reinforcing your own beliefs
  ifelse cluster = "optimistic"
    [set risk (risk - random-float max_reinforcement) set benefit (benefit + random-float max_reinforcement)]
    [ifelse cluster = "neutral"
      [set risk (risk - random-float max_reinforcement) set benefit (benefit - random-float max_reinforcement)]
      [ifelse cluster = "alarmed"
        [set risk (risk + random-float max_reinforcement) set benefit (benefit - random-float max_reinforcement)]
        [set risk (risk + random-float max_reinforcement) set benefit (benefit + random-float max_reinforcement)]
    ]
  ]


  if debug? [
    print "reinforce"
    print risk
    print benefit]

;; If there is a high knowledge development (>0) the risk is lower and benefit higher.
;; if there is a low knowledge development (<0) the risk is higher and the benefit lower.

  set risk (risk + (- weight_knowledge_dev) * knowledge_dev)
  set benefit (benefit + weight_knowledge_dev * knowledge_dev)

  if debug? [
    print "know"
    print risk
    print benefit]

;; high trust = low risk

  set risk (risk + (- weight_trust_government) * trust_government)

  if debug? [
    print "trust gov"
    print risk
    print benefit]

;; high perceived control = low risk (vice versa) (Favorably or negative regulations?)

  set risk (risk + (- weight_regulations) * regulations)
  set benefit (benefit + (weight_regulations) * regulations)

  if debug? [
    print "regulations"
    print risk
    print benefit]


;; If there is a high water demand, there is a higher benefit and lower perceived risk (the benefit is assumed)
;; If there is a low water demand, there is a higer perceived risk and lower benefit (the benefit is assumed)
  if is-farmer? self [

    set benefit (benefit + weight_water_demand * water_demand )
    set risk (risk + weight_water_demand * water_demand )

    if debug? [
    print "w demand"
    print risk
    print benefit]


    set risk (risk + (- weight_GDP) * GDP)

    if debug? [
    print "GDP"
    print risk
    print benefit]

;; if there is a high confidence rainfall will be enough, there is a lower perceived risk

    set risk (risk + (- weight_rainfall) * rainfall)
    set benefit (benefit + (- weight_rainfall) * rainfall)

    if debug? [
    print "rainfall"
    print risk
    print benefit]

  ]

  if is-consumer? self [

    set risk (risk + (- weight_trust_agriculture) * trust_agriculture)

    if debug? [
    print "trust agri"
    print risk
    print benefit]


  ]


  setRandB risk benefit
  changecluster
  setxy risk benefit

  if debug? [
    print self
    print "my new risk and benefit"
    print risk
    print benefit]


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
   set new_risk ([risk] of person1 - ((([risk] of person1 - avg_conversation_risk) / F)) / conversation_calibration)
   set new_benefit ([benefit] of person1 - ((([benefit] of person1 - avg_conversation_benefit) / F) / conversation_calibration))
   setRandB new_risk new_benefit
   changecluster
   setxy risk benefit]

  ask person2 [
   set new_risk ([risk] of person2 - ((([risk] of person2 - avg_conversation_risk) / F)/ conversation_calibration ))
   set new_benefit ([benefit] of person2 - ((([benefit] of person2 - avg_conversation_benefit) / F) / conversation_calibration))
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
  ; Stay inbound of the range
  ifelse 0 < temp_risk and temp_risk < 70
    [set risk temp_risk]
    [ifelse temp_risk >= 70
      [set risk 70]
      [set risk 0]
    ]

  if debug? [
    print "after conv"
      print "new risk"
      print risk
    ]

  ; Stay inbound of the range
  ifelse 0 < temp_benefit and temp_benefit < 70
    [set benefit temp_benefit]
    [ifelse temp_benefit >= 70
      [set benefit 70]
      [set benefit 0]
    ]
  if debug? [
      print "new benefit"
      print benefit
    ]
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
        [set ext_factors_list replace-item i ext_factors_list max (list -1 (x - gradual_change))]
        [ifelse item i ext_rate_list = "medium"
          [set ext_factors_list replace-item i ext_factors_list max (list -1 (x - medium_change))]
          [set ext_factors_list replace-item i ext_factors_list max (list -1 (x - random-float max_abrupt_change))] ; abrupt change is not consistent
        ]
    ]
      [if item i ext_change_list = "increasing"
        [ifelse item i ext_rate_list = "gradual"
          [set ext_factors_list replace-item i ext_factors_list min (list 1 (x + gradual_change))]
          [ifelse item i ext_rate_list = "medium"
           [set ext_factors_list replace-item i ext_factors_list min (list 1 (x + medium_change))]
           [set ext_factors_list replace-item i ext_factors_list min (list 1 (x + random-float max_abrupt_change))] ; abrupt change is not consistent
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
  set GDP 0
  set rainfall 0
  set water_demand 0
  set regulations 0
  set trust_agriculture 0
  set trust_government 0
  set knowledge_dev 0
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
22
701
194
734
leader_influence
leader_influence
1
10
10.0
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
100.0
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
100
100.0
4
1
NIL
HORIZONTAL

SWITCH
295
489
398
522
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
9.0
1
1
NIL
HORIZONTAL

CHOOSER
175
93
313
138
GDP_change
GDP_change
"decreasing" "constant" "increasing"
1

CHOOSER
313
93
460
138
GDP_change_r
GDP_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
175
138
313
183
rainfall_change
rainfall_change
"decreasing" "constant" "increasing"
1

CHOOSER
313
139
460
184
rainfall_change_r
rainfall_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
176
231
314
276
regulations_change
regulations_change
"decreasing" "constant" "increasing"
1

CHOOSER
176
277
314
322
trust_agri_change
trust_agri_change
"decreasing" "constant" "increasing"
1

CHOOSER
176
185
314
230
w_demand_change
w_demand_change
"decreasing" "constant" "increasing"
1

CHOOSER
314
185
459
230
w_demand_change_r
w_demand_change_r
"gradual" "medium" "abrupt"
0

CHOOSER
314
231
459
276
regulations_change_r
regulations_change_r
"gradual" "medium" "abrupt"
0

CHOOSER
314
277
459
322
trust_agri_change_r
trust_agri_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
175
323
313
368
trust_gov_change
trust_gov_change
"decreasing" "constant" "increasing"
1

CHOOSER
313
323
458
368
trust_gov_change_r
trust_gov_change_r
"gradual" "medium" "abrupt"
2

CHOOSER
175
369
313
414
know_dev_change
know_dev_change
"decreasing" "constant" "increasing"
1

CHOOSER
313
369
458
414
know_dev_change_r
know_dev_change_r
"gradual" "medium" "abrupt"
2

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

MONITOR
26
93
175
138
GDP
GDP
5
1
11

MONITOR
26
139
175
184
Rainfall
Rainfall
5
1
11

MONITOR
26
185
176
230
Water Demand
water_demand
5
1
11

MONITOR
26
231
176
276
Regulations
regulations
5
1
11

MONITOR
26
277
176
322
Trust in agriculture
trust_agriculture
5
1
11

MONITOR
26
323
175
368
Trust in Government
trust_government
5
1
11

MONITOR
26
369
175
414
Knowledge Development
knowledge_dev
5
1
11

SLIDER
459
98
631
131
GDP
GDP
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
459
144
631
177
rainfall
rainfall
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
458
191
630
224
water_demand
water_demand
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
459
238
631
271
regulations
regulations
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
459
282
631
315
trust_agriculture
trust_agriculture
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
458
330
630
363
trust_government
trust_government
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
457
375
629
408
knowledge_dev
knowledge_dev
-1
1
0.0
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The model in this report is made for a 10-week course on Advanced Agent based modeling at the TU Delft, in assignment for KWR. The objective is to find out how consumer's and farmer's risk and benefit perception of water reuse for irrigation develops. 

## HOW IT WORKS

Farmer/Consumer wakes up and gets something to drink and reads news about the environment around them. Environment is created by external factors which are continuously changing.  This activity influenced their perceived risk and benefit in terms of the irrigation water reuse system. That determines their risk and benefit levels. After that they start working and discuss the news with one peer within their network. Both agents adapt their perceived risk and benefit according to their average. After coming back home and sleeping, the new week begins.

Some agents are leaders. They have more influence on others than normal agents and they are less influenced by others. Leaders do not like to hang out with other leaders. They avoid competition. Therefore, leaders can only interact with normal agents. Leaders talk to several agents at the same time within their networks. 

## HOW TO USE IT

Model resets external factors to 0 in setup. The model is meant to study the behavior when and how factors change.

Parameter		   :Range or value	


Final time:    	    1560	

Is there change? If so, which direction?  
 
GDP_change    		    :decreasing, constant, increasing
w_demand_change	    :decreasing, constant, increasing	   
regulations_change	    :decreasing, constant, increasing	    
trust_agri_change	    :decreasing, constant, increasing    
trust_gov_change	    :decreasing, constant, increasing	    
know_dev_change	    :decreasing, constant, increasing	

Is there change? If so, how much? 
   
GDP_change_r	    	    :gradual, medium, abrupt
rainfall_change_r	    :gradual, medium, abrupt	    
w_demand_change_r	    :gradual, medium, abrupt	    
regulations_change_r	    :gradual, medium, abrupt	    
trust_agri_change_r	    :gradual, medium, abrupt	    
trust_gov_change_r	    :gradual, medium, abrupt	    
know_dev_change_r	    :gradual, medium, abrupt	

How many agents?
    
No_consumers	    	    :4 - 100	    
No_farmers    		    :4 - 20	

How many agents can a leader reach? (Normal agents have network size 6)
    
Leader_network_size	    :6 - 12	

What percentage of agents are leaders?
  
consumer_leaders    	    :0 - 0.25	    
farmer_leaders	    	    :0 - 0.25	

How much influence do leaders have?
    
leader_influence    	    :1 - 10

## THINGS TO NOTICE


When external factors are 0 and changes are set to constant they do not influence the model. Only interaction changes risk and benefit of agents then.

## THINGS TO TRY

There are sliders left in the model so the user can modify the value of external factors during the run to see how agents respond to external factors.

## EXTENDING THE MODEL

Changes in external factors are now only decreasing, constant, or, increasing during the model run. One can imagine that normally it might decrease a while and after that increase again.

In the first conceptualization of the model consumer average risk and benefit had influence on farmers, however this is not yet implemented.

## NETLOGO FEATURES

For the analysis of this model EMA_workbench library for Python was used. This is done in a seperate notebook.

## RELATED MODELS
This model was inspired by:

Kandiah, V. K., Berglund, E. Z., & Binder, A. R. (2019). An agent-based modeling approach to project adoption of water reuse and evaluate expansion plans within a sociotechnical water infrastructure system. Sustainable Cities and Society, 46, 101412.

Kraan, O., Dalderop, S., Kramer, G. J., & Nikolic, I. (2019). Jumping to a better world: An agent-based exploration of criticality in low-carbon energy transitions. Energy Research & Social Science, 47, 156-165.


## CREDITS AND REFERENCES
Distribution for weights derived from:

Duinen, R. V., Filatova, T., Geurts, P., & Veen, A. V. D. (2015). Empirical analysis of farmers' drought risk perception: Objective factors, personal circumstances, and social influence. Risk analysis, 35(4), 741-755.

Lazaridou, D., Michailidis, A., & Trigkas, M. (2018). Farmers’ Attitudes Toward Recycled Water Use in Irrigated Agriculture. KnE Social Sciences, 157-165.

Michetti, M., Raggi, M., Guerra, E., & Viaggi, D. (2019). Interpreting farmers’ perceptions of risks and benefits concerning wastewater reuse for irrigation: a case study in Emilia-Romagna (Italy). Water, 11(1), 108.


Nancarrow, B. E., Leviston, Z., Po, M., Porter, N. B., & Tucker, D. I. (2008). What drives communities' decisions and behaviours in the reuse of wastewater. Water Science and Technology, 57(4), 485-491.
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
