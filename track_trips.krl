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
          "events": [ { "domain": "echo", "type": "message","attrs": [ "mileage" ] }]
        }
  }
  
  rule process_trip {
	select when echo message
	pre{
		miles = event:attr("mileage")
	}
	send_directive("trip", {"length":miles})
  }
  
  
}