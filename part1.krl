ruleset part1 {
  meta {
    name "Part 1"
    description <<
Part 1 of the Pico Lab
>>
    author "Brandon Twede"
    logging on
    shares message, __testing
  }
  
  global {
	  __testing = { "queries": [ 
                       { "name": "__testing" } ],
          "events": [ { "domain": "echo", "type": "hello" },
          { "domain": "echo", "type": "message", "attrs": [ "input" ] }]
        }
  }
  
  rule hello {
	select when echo hello
	send_directive("say", {"something":"Hello World"})
  }
  
  rule message {
	select when echo message
	pre{
		input = event:attr("input")
	}
	send_directive("say", {"something":input})
  }

  
}