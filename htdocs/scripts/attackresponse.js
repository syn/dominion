
function setupMilitia() {
	statusbackup = $("#playstatus").html();
	handactive('attack');
	$("#playstatus").html("Your are under attack from a Miliat, Discard down to 3 cards or play a reaction");
	$('#handcards').children(".card").each(function(index,value) {
		//Get the id of the supply.
		//alert ($('#' + value.id).attr("cardnum"));
		//var type = hand[$('#' + value.id).attr("cardnum")].type;
		//if(type =='Action/Reaction' ) {
		$('#' + value.id).draggable({helper: clonehelper});
		$('#' + value.id).fadeTo('fast', 1);
		//} else {
			//$('#' + value.id).draggable();
		//}
	});
	discards = new Array();
	$("#play").droppable({
        accept: '.card',
        drop: function(event, ui) {
			var card = $(ui.draggable);
            
            if(hand[card.attr("cardnum")].name == 'Moat' && discards.length == 0) {
            	var c = card.clone();
                var oldid = c.attr('id');
                c.removeAttr("id");
                c.removeClass("ui-draggable");
                card.draggable("disable");
                
                updateLocalCardPlayed(c,'Militiaresolve');
        		var message = new militiaResolved('Moat','');
        		showhand();
        		$("#play").droppable( "destroy" );
        		$("#playstatus").html(statusbackup);
        		
            	var myJSONText = JSON.stringify(message);
            	ws.send(myJSONText);
            	
        	} else {
        		card.attr('style','');
                card.draggable("disable");
                
        		//Append the card onto the discards array.
                discards.push(hand[card.attr("cardnum")].name);
                hand[card.attr("cardnum")]="played";
                updateLocalCardPlayed(card,'Militiaresolve');
                //Figure out how many cards are left in their hand
                count = 0;
                for ( var i in hand )
            	{
            		if(hand[i] != 'played') {
            			count++;
            		}
            	}
                if(count == 3) {
                	var message = new militiaResolved('Victory',discards);
                	var myJSONText = JSON.stringify(message);
                	showhand();
            		$("#play").droppable( "destroy" );
            		$("#playstatus").html(statusbackup);
            		handdeactivate();
                	ws.send(myJSONText);
                }
        	}
        }
    });
	
	
	
}

function setupBureaucrat() {
	handactive('attack');
	statusbackup = $("#playstatus").html();
	$("#playstatus").html("Your are under attack from a Bureucrat, Select a Victory card to Put ontop of your Deck, or play a Reaction");
	$('#handcards').children(".card").each(function(index,value) {
		//Get the id of the supply.
		//alert ($('#' + value.id).attr("cardnum"));
		var type = hand[$('#' + value.id).attr("cardnum")].type;
		if(type =='Action/Reaction' || type =='Victory' ) {
			$('#' + value.id).draggable({ 
		        revert: 'invalid', 
		        scroll: false,
		        helper: function(){ 
					var c = $(this).clone();
					c.width($(this).width());
					c.height($(this).height());
					c.attr('id','tempclonecard');
					
					return c;
				},
		        start : function() {
		        	this.style.display="none";
		        },
		        stop: function() {
		        	this.style.display="";
		        }
		    });
		} else {
			$('#' + value.id).fadeTo('slow', 0.4);
		}
	});
		
	//Now go through the current hand looking for reaction cards
	
	$("#play").droppable({
        accept: '.card',
        drop: function(event, ui) {
				var card = $(ui.draggable);
                
                
                if(hand[card.attr("cardnum")].name == 'Moat') {
                	var c = card.clone();
                    var oldid = c.attr('id');
                    c.removeAttr("id");
                    c.removeClass("ui-draggable");
                    card.draggable("disable");
                    updateLocalCardPlayed(c,'bureaucratresolve');
                    var message = new bureaucratResolved('Moat','');
                	var myJSONText = JSON.stringify(message);
                	$("#playstatus").html(statusbackup);
                	ws.send(myJSONText);
            	}
                
                if(hand[card.attr("cardnum")].type == 'Victory') {
                	card.attr('style','');
                	card.draggable("destroy");
					card.attr('style','');  //Jquery seems to leave a bunch of relative references around after dragging with out the clone helper.
                    updateLocalCardPlayed(card,'bureaucratresolve');
                    
                    var message = new bureaucratResolved('Victory',hand[card.attr("cardnum")].name);
            		hand[card.attr("cardnum")]="played";
            		$("#playstatus").html(statusbackup);
                	var myJSONText = JSON.stringify(message);
                	ws.send(myJSONText);
            	}
                
                //Reset the supply
                handdeactivate();
        		showsupply();
        		showhand();
        		$("#tempclonecard").remove();
        		$("#play").droppable( "destroy" );
        }
    });
}


function setupWitch() {
	handactive('attack');
	supplyactive('attack');
	statusbackup = $("#playstatus").html();
	$("#playstatus").html("Your are under attack from a Witch, Take a curse or play a Reaction");
	$('#supplycards').children(".card").each(function(index,value) {
		//Get the id of the supply.
		if(value.id == 'supplycard-Curse') {
			$('#' + value.id).draggable({helper: clonehelper});
			$('#' + value.id).fadeTo('fast', 1);
		} else {
			$('#' + value.id).fadeTo('slow', 0.2);
		}
	});
	
	$('#handcards').children(".card").each(function(index,value) {
		//Get the id of the supply.
		//alert ($('#' + value.id).attr("cardnum"));
		var type = hand[$('#' + value.id).attr("cardnum")].type;
		if(type =='Action/Reaction' ) {
			$('#' + value.id).draggable({helper: clonehelper});
			$('#' + value.id).fadeTo('fast', 1);
		} else {					
			$('#' + value.id).fadeTo('slow', 0.4);
		}
	});
		
	//Now go through the current hand looking for reaction cards
	
	$("#play").droppable({
        accept: '.card',
        drop: function(event, ui) {
                var c = $(ui.draggable).clone();
                var oldid = c.attr('id');
                c.removeAttr("id");
				//$("#playedcards").append(c);
                c.removeClass("ui-draggable");
                updateLocalCardPlayed(c,'witchresolve');
                
                
                if(oldid == 'supplycard-Curse') {
                	//Send a message that says we resolve the witch attak by taking a curse card
                	var message = new witchResolved('Curse');
                	var myJSONText = JSON.stringify(message);
                	ws.send(myJSONText); 
                } else {
                	//See if it was a moat
                	if(hand[c.attr("cardnum")].name == 'Moat') {
                		var message = new witchResolved('Moat');
                    	var myJSONText = JSON.stringify(message);
                    	ws.send(myJSONText);
                	}
                }
                $("#playstatus").html(statusbackup);
                
                supplydeactivate();
                handdeactivate();
                //Reset the supply
        		showsupply();
        		showhand();
        		$("#play").droppable( "destroy" );
        }
    });
}
