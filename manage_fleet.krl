ruleset manage_fleet {
  meta {
    name "manage_fleet"
    description <<Lab 7>>
    author "Brandon Twede"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias Subscriptions
    logging on
    shares __testing, vehicles, save_subscription, store_new_child, create_vehicle,
      delete_vehicle, gather_report, compile_report, save_report, get_report_function, five_latest_reports
  }
  
  global {
    __testing = { "queries":
      [ { "name": "__testing" }, {"name": "vehicles"}, {"name": "get_report_function"},
        {"name": "five_latest_reports"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      { "domain": "car", "type": "new_vehicle", "attrs": [ "section_id" ] },
      { "domain": "car", "type": "unneeded_vehicle", "attrs": [ "section_id" ] },
      { "domain": "fleet", "type":"gather", "attrs":[]}
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    vehicles = function(){
      Subscriptions:established("Tx_role","vehicle")
    }
    get_report_function = function() {
      length = ent:sections.keys().length();
      report = ent:sections.map(function(v,k){
        response = wrangler:skyQuery(v{"eci"}, "trip_store", "trips", {});
        car = {"vehicles": length, "responding":length, "trips":response};
        car;
      });
      report;
    }
    five_latest_reports = function() {
      ent:five_report;
      //result = 
    }
  }
  
  rule clear_temp_report {
    select when fleet gather
    always {
      ent:temp_report := {};
    }
  }
  
  
  rule gather_report {
    select when fleet gather
    foreach Subscriptions:established("Tx_role","vehicle") setting (subscription)
    pre {
    }
    event:send(
      { "eci": subscription{"Tx"}, "eid": "send-report",
        "domain": "car", "type": "send_report" }
    )
  }
  
  rule schedule_report_finish {
    select when fleet gather
    fired{
      schedule fleet event "report_done" at time:add(time:now(), {"seconds": 5})
        attributes event:attrs
    }
  }
  

  rule compile_report {
    select when fleet receive_report
    pre{
      trips = event:attr("trips")
      name = event:attr("name")
    }
    always{
      ent:temp_report := ent:temp_report.put([name], trips);
    }
  }
  
  rule save_report {
    select when fleet report_done
    pre {
      vehicles = Subscriptions:established("Tx_role","vehicle").values().length();
      reporting = ent:temp_report.values().length();
      result = ent:temp_report.map(function(v,k){
        car = {"vehicles": vehicles, "responding":reporting, "trips":v};
        car;
        });
    }
    fired {
     ent:five_report := ent:five_report.defaultsTo([]);
     ent:five_report := ent:five_report.slice(3) if ent:five_report.keys().length() >4;
     ent:five_report := result.append(ent:five_report);
    }
  }
  
  rule save_subscription {
    select when wrangler outbound_pending_subscription_approved 
    pre {
      tx = event:attr("Tx")
      name = event:attr("name")
    }
    always {
      //ent:sections{name}{["Tx"]} := tx;
      ent:sections := ent:sections.put([name,"tx"], tx);
    }
  }
  
  rule store_new_child {
  select when wrangler child_initialized
  pre {
    the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
    section_id = event:attr("rs_attrs"){"section_id"}
  }
  if section_id.klog("found section_id")
  then
    noop()
  fired {
    ent:sections := ent:sections.defaultsTo({});
    ent:sections{["Car " + section_id]} := the_section;
    raise wrangler event "subscription"
          attributes
         { "name" : "Car " + section_id,
           "Rx_role": "fleet",
           "Tx_role": "vehicle",
           "channel_type": "subscription",
           "wellKnown_Tx" : ent:sections{"Car " + section_id}{"eci"}
         }
    }
  }
  
  
  rule create_vehicle {
    select when car new_vehicle
    pre{
      section_id = event:attr("section_id")
    }
    always {
      raise wrangler event "child_creation"
      attributes { "name": "Car " + section_id,
               "color": "#ffff00",
               "section_id": section_id,
               "rids": ["track_trips", "trip_store"] };

    }
  }
    
  rule delete_vehicle {
    select when car unneeded_vehicle 
    pre{
      section_id = event:attr("section_id")
      tx = ent:sections{"Car " + section_id}{"tx"}
    }
    always{
        raise wrangler event "subscription_cancellation"
          attributes {"Tx":tx};
        raise wrangler event "child_deletion"
          attributes {"name": "Car " + section_id};
        ent:sections := ent:sections.delete("Car " + section_id);
        
    }
  }
}
