ruleset track_trips {
  meta {
    name "track_trips"
    description <<
Part 1, track_trips of the Pico Lab
>>
    author "Brandon Twede"
    logging on
    shares process_trip, __testing
  }
  
  global {
	  __testing = { "queries": [ 
                       { "name": "__testing" } ],
          "events": [ { "domain": "car", "type": "new_trip","attrs": [ "mileage" ] }]
        }
    long_trip = 10
  }
  
  rule auto_accept {
  select when wrangler inbound_pending_subscription_added
  fired {
    raise wrangler event "pending_subscription_approval"
      attributes event:attrs
  }
}
  
  rule process_trip {
  	select when car new_trip
  	pre{
  		miles = event:attr("mileage")
  	}
  	send_directive("trip", {"length":miles})
  	always {
  	  raise explicit event "trip_processed"
  	    attributes {"mileage":miles, "timestamp":time:now()}//event:attrs
  	}
  }
  
  rule find_long_trips {
    select when explicit trip_processed
    pre {
      miles = event:attr("mileage")
      time = event:attr("timestamp")
    }
    always {
      raise explicit event "found_long_trip" attributes {"mileage":miles, "timestamp":time} if (miles > long_trip);
    }
  }
  
  rule found_long_trip {
    select when explicit found_long_trip
    send_directive("say", {"something":"Long Trip Found"})
  }
  
  
}