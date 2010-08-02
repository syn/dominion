
function nameupdate(parameter) {
	this.type = "namechange";
	this.name = parameter;
}

function buycard(parameter) {
	this.type = "buycard";
	this.card = parameter;
}

function playcard(parameter) {
	this.type = "playcard";
	this.card = parameter;
}
function choiceresponse(parameter,card) {
	this.type = "choiceresponse";
	this.event = parameter;
	if(card) {this.card = card;}
}


function startgame() {
	this.type = "startgame";
}

function finishturn() {
	this.type = "finishturn";
} 
function finishactionphase () {
	this.type = "finishactionphase";
}
function witchResolved(parameter) {
	this.type = "witchResolved";
	this.option = parameter;
}

function bureaucratResolved(parameter,vpcard) {
	this.type = "bureaucratResolved";
	this.option = parameter;
	this.card = vpcard;
}
function militiaResolved(resolution,discards) {
	this.type = "militiaResolved";
	this.option = resolution;
	this.card = discards;
}

if (WebSocket.__initialize) {
	// Set URL of your WebSocketMain.swf here:
	WebSocket.__swfLocation = 'web-socket-js/WebSocketMain.swf';
}

// example copied from web-socket-js/sample.html
var ws, input, clock;

var supply;
var hand;
var gold;
var buys;
var discards; //Used by Militia, for when the player has to discard multiple cards
var lastPlayUpdate;
var actioncount=0;
var statusbackup = "";  // used when I have to temporarily replace the status message
var gameover = false;
function init() {
	if (localStorage.getItem('playername')) {
		$('#chatname').html(localStorage.getItem('playername'));
	}
	// Connect to Web Socket.
	ws = new WebSocket('ws://localhost:3000');
	
	ws.onclose = function (event) {
		addChatMessage("Your browser","The server seems to have up and quit on us!");
	};
	ws.onopen = function (event) {
		if (localStorage.getItem('playername')) {
			changename(localStorage.getItem('playername'));
		}
	}
	// Receive message
	ws.onmessage = function(e) {
		// Write message
		//addChatMessage('Debug',e.data);
		var com = jQuery.parseJSON(e.data);
		if (com.type == 'message') {
			addChatMessage(com.from,com.message);
			return;
		}
		if (com.type =='InitialSetup') {
			var message = document.createElement('div');
			message.appendChild(document.createTextNode("Initial Setup recived"));
			var display = document.getElementById('chatdisplay');
			display.appendChild(message);
			
			if (localStorage.getItem('playername')) {
				changename(localStorage.getItem('playername'));
			} else {
				var display = document.getElementById('chatname');
				display.innerHTML = com.name;
			}
			if(com.gamestatus == 'pregame') {
				//DO some stuff like add a start game button
				var control = document.getElementById('control');
				var startbutton = document.createElement('div');
				startbutton.setAttribute("id", "startcontainer");
				startbutton.innerHTML="<button type='button' id='startgame'>Start Game!</button>";
				control.appendChild(startbutton);
				$('#startgame').click(function() {
					var message = new startgame();
					ws.send(JSON.stringify(message));
				});
			}
			return;
		}
		if (com.type =='playerstatus') {
			switch(com.action)
			{
			case 'joined':
				var playerstatus = document.createElement('li');
				playerstatus.setAttribute("id", "playerstatus"+com.playerid);
				playerstatus.innerHTML=com.name;
				document.getElementById('playerstatus').appendChild(playerstatus);
				break;
			case 'namechange':
				document.getElementById("playerstatus"+com.playerid).innerHTML=com.name;
				break;
			case 'quit':
				addChatMessage('System',com.name + " has left.");
				document.getElementById('playerstatus').removeChild(document.getElementById("playerstatus"+com.playerid));
				break;
			case 'action':
				$('#playerstatus'+com.playerid).removeClass();
				$('#playerstatus'+com.playerid).addClass('action');
				break;
			case 'buy':
				$('#playerstatus'+com.playerid).removeClass();
				$('#playerstatus'+com.playerid).addClass('buy');
				break;
			case 'waiting':  //waiting for other players
				$('#playerstatus'+com.playerid).removeClass();
				$('#playerstatus'+com.playerid).addClass('waiting');
				break;
			}
			return;
		}
		
		if (com.type == 'startgame') {
			 //Remove the startgame button
			document.getElementById('control').removeChild(document.getElementById("startcontainer"));
			addChatMessage('System',"The game has started.");
			return;
		}
		if (com.type =='supply') {
			//Setup the supply for the start of the game
			supply = com.supply;
			showsupply();
			if(buys > 0) {
				//We were in the middle of buy phase and we got sent an updated supply, setup the dragging again.
				$('#supplycards').children(".card").each(function(index,value) {
					if(gold >= supply[$('#' + value.id).attr("cardnum")].costgold && supply[$('#' + value.id).attr("cardnum")].available > 0) {
						$('#' + value.id).draggable({helper: clonehelper});
					} else {
						$('#' + value.id).fadeTo('slow', 0.2);
					}
				});
			}
			return;
		}
		if (com.type == 'newhand') {
			hand = com.cards;
			showhand();
			return;
		}
		if (com.type == 'endgame') {
			//Game over man.
			addChatMessage('Debug','Game over -' + e.data);
			//Build up the player results list.
			$('#hand').html('');
			$('#supply').html("<h1>Game Over</h1>" );
			for ( var i in com.results )
			{
				var resultp = document.createElement('p');
				resultp.innerHTML=com.results[i].name + " score : "+ com.results[i].vp;
				$('#supply').append(resultp);
			}
			gameover = true; 
			return;
		}
		if (com.type == 'extracards') {
			hand = hand.concat(com.cards);
			showhand();
			return;
		}
		if (com.type == 'startphasebuy') {
			startbuyphase(com);
			return;
		}
		if (com.type == 'cardplayed') { 
			//Add the card to the play area to show everyone what was played.
			updateCardPlayed(com.playerid,com.card,com.actiontype,com.name);
			return;
		}
		if (com.type == 'startactionphase') {
			startactionphase(com);
			return;
		}
		if(com.type =='actionresolved') {
			//see if there are any actions left
			if(com.actions == 0) {
				//Cleanup from the buy phase
				//document.getElementById('control').removeChild(document.getElementById("skipActionContainer"));
				//Remove the dragable stuff on the cards in the hand.
				preparehandforbuy();
			} else {
				//update the status
				$("#playstatus").html("Action Phase : actions left = " + com.actions);
			}
			return;
		}
		if(com.type == 'attack') {
			if(com.card == 'Witch') {
				setupWitch();
			}
			if(com.card == 'Bureaucrat') {
				setupBureaucrat();
			}
			if(com.card == 'Militia') {
				setupMilitia();
			}
			return;
		}
		if(com.type == 'choice') {
			//We have some kind of choice to make
			var endbutton = "";
			var trashevent = "";
			var discardevent = "";
			statusbackup = $("#playstatus").html();
			$("#playstatus").html(com.message);
			for ( var i in com.choice )
			{
				switch(com.choice[i].type)
				{
				case 'button':
					//add a button to the control area with the requested message and action.
					var choicebutton = document.createElement('button');
					choicebutton.setAttribute("id", com.choice[i].event);
					choicebutton.setAttribute("type","button");
					choicebutton.innerHTML=com.choice[i].name;
					buttonevent = com.choice[i].event;
					$('#control').append(choicebutton);
					$('#'+com.choice[i].event).click(function() {
						var message = new choiceresponse(buttonevent);
						ws.send(JSON.stringify(message));
						handdeactivate();
						trashdeactivate();
						discarddeactivate();
						supplydeactivate();
						$("#trash").droppable( "destroy" );
						$("#play").droppable( "destroy" );
						$("#discard").droppable( "destroy" );
						//Remove the button
						$(this).remove();
						$("#playstatus").html(statusbackup);
					});
					endbutton = com.choice[i].event;
					break;
				case 'trash':
					//Setup the hand so cards can be trashed
					makehanddraggable(com.choice[i].cards);
					//Setup the trash area as dropable
					trashactive('trashon');
					handactive('action');
					trashevent = com.choice[i].event;
					$("#trash").droppable({
				        accept: '.card',
				        drop: function(event, ui) {
							var card = $(ui.draggable);
			                //c.removeAttr("id");
							//$("#playedcards").append(card);
							
							card.draggable("destroy");
							card.attr('style','');  //Jquery seems to leave a bunch of relative references around after dragging with out the clone helper.
			            
							updateLocalCardPlayed(card,'Trash');
							
							//Remove all the dragable stuff currently setup, it may interfer with resolving the action.
							$('#handcards').children(".card").each(function(index,value) {
								$('#' + value.id).draggable("destroy");
							});
							$("#trash").droppable( "destroy" );
							handdeactivate();
							trashdeactivate();
							
			                //Send a message off that says we just played a card.
							//TODO make the name of the event get carried over
							var message = new choiceresponse(trashevent,hand[card.attr("cardnum")].name);
			            	
							//replace the card with a filler
			                hand[card.attr("cardnum")]="played";
			                showhand();
			                ws.send(JSON.stringify(message,hand[card.attr("cardnum")].name));
			            	$("#tempclonecard").remove();
			            	
			            	if( endbutton != null && endbutton != "") {
			            		$('#' + endbutton).remove();
			            	}
			            	$("#playstatus").html(statusbackup);
						}
					});	
					break;
				case 'discard':
					//Setup the hand so cards can be trashed
					makehanddraggable(com.choice[i].cards);
					//Setup the trash area as dropable
					discardactive('discardon');
					handactive('action');
					discardevent = com.choice[i].event;
					$("#discard").droppable({
				        accept: '.card',
				        drop: function(event, ui) {
							var card = $(ui.draggable);
			                //c.removeAttr("id");
							//$("#playedcards").append(card);
							
							card.draggable("destroy");
							card.attr('style','');  //Jquery seems to leave a bunch of relative references around after dragging with out the clone helper.
			            
							updateLocalCardPlayed(card,'Discard');
							
							//Remove all the dragable stuff currently setup, it may interfer with resolving the action.
							$('#handcards').children(".card").each(function(index,value) {
								$('#' + value.id).draggable("destroy");
							});
							$("#trash").droppable( "destroy" );
							handdeactivate();
							discarddeactivate();
							
			                //Send a message off that says we just played a card.
							//TODO make the name of the event get carried over
							var message = new choiceresponse(discardevent,hand[card.attr("cardnum")].name);
			            	
							//replace the card with a filler
			                hand[card.attr("cardnum")]="played";
			                showhand();
			                ws.send(JSON.stringify(message,hand[card.attr("cardnum")].name));
			            	$("#tempclonecard").remove();
			            	if( endbutton != null && endbutton != "") {
			            		$('#' + endbutton).remove();
			            	}
			            	$("#playstatus").html(statusbackup);
						}
					});	
					break;
					case 'buy':
						//Setup the hand so cards can be trashed
						makesupplydraggable(com.choice[i].cards);
						//Setup the trash area as dropable
						supplyactive('buy');
						buyevent = com.choice[i].event;
						$("#play").droppable({
					        accept: '.card',
					        drop: function(event, ui) {
							
								var card = $(ui.draggable).clone();
				                card.removeAttr("id");
								card.removeClass("ui-draggable");
							
								//card.draggable("destroy");
								//card.attr('style','');  //Jquery seems to leave a bunch of relative references around after dragging with out the clone helper.
				            
								updateLocalCardPlayed(card,'cardbrought');
								
								//Remove all the dragable stuff currently setup, it may interfer with resolving the action.
								$('#handcards').children(".card").each(function(index,value) {
									$('#' + value.id).draggable("destroy");
								});
								$("#play").droppable( "destroy" );
								supplydeactivate();
								
				                //Send a message off that says we just played a card.
								//TODO make the name of the event get carried over
								var message = new choiceresponse(buyevent,supply[card.attr("cardnum")].name);
				            								
				                ws.send(JSON.stringify(message,supply[card.attr("cardnum")].name));
				            	$("#tempclonecard").remove();
				            	if( endbutton != null && endbutton != "") {
				            		$('#' + endbutton).remove();
				            	}
				            	$("#playstatus").html(statusbackup);
							}
							
						});	
						break;
					case 'play':
						//Setup the hand so cards can be played
						makehanddraggable(com.choice[i].cards);
						handactive('action');
						playevent = com.choice[i].event;
						$("#play").droppable({
					        accept: '.card',
					        drop: function(event, ui) {
								var card = $(ui.draggable);
				                //c.removeAttr("id");
								//$("#playedcards").append(card);
								
								card.draggable("destroy");
								card.attr('style','');  //Jquery seems to leave a bunch of relative references around after dragging with out the clone helper.
				            
								updateLocalCardPlayed(card,'actionplayed');
								
								//Remove all the dragable stuff currently setup, it may interfer with resolving the action.
								$('#handcards').children(".card").each(function(index,value) {
									$('#' + value.id).draggable("destroy");
								});
								$("#play").droppable( "destroy" );
								handdeactivate();
								
				                //Send a message off that says we just played a card.
								//TODO make the name of the event get carried over
								var message = new choiceresponse(playevent,hand[card.attr("cardnum")].name);
				            	
								//replace the card with a filler
				                hand[card.attr("cardnum")]="played";
				                showhand();
				                ws.send(JSON.stringify(message,hand[card.attr("cardnum")].name));
				            	$("#tempclonecard").remove();
				            	if( endbutton != null && endbutton != "") {
				            		$('#' + endbutton).remove();
				            	}
				            	$("#playstatus").html(statusbackup);
							}
						});	
						break;
				}
			}
		}
		//addChatMessage('Debug',e.data);
	};
	
	
	$('#chatname').blur(function() {
		changename(this.innerHTML);
	});
}

function makehanddraggable (cards) {
	var oldarr = new Array();
	for ( var i in cards ) {
		oldarr.push(cards[i].name);
	}
	oldarr.sort();j=0;
	newarr= new Array();
	for(var i=0;i<oldarr.length;i++){
		newarr[j]=oldarr[i];j++;
		if((i>0)&&(oldarr[i]==oldarr[i-1])){
			newarr.pop();
			j--;
		}
	}
	var cardsdraggable = new Array();
	for ( var i in newarr ) {
		
		$('#handcards').children(".card-"+newarr[i]).each(function(index,value) {
			//TODO only make the cards in the choice type draggable...
			//For chapple that dosn't matter :D
			
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
			
			$('#' + value.id).fadeTo('fast', 1);
			cardsdraggable.push($(this).attr('id'));
			
		});
	}
	//Iterate over all the cards in the hand making those not dragable greyed out.
	$('#handcards').children(".card").each(function(index,value) {
		
		if(cardsdraggable.indexOf($(this).attr('id'))==-1) {
			$(this).fadeTo('slow', 0.2);
		}
	});
		
}
function makesupplydraggable ( cards) {
	var oldarr = new Array();
	for ( var i in cards ) {
		oldarr.push(cards[i].name);
	}
	
	oldarr.sort();j=0;
	newarr= new Array();
	for(var i=0;i<oldarr.length;i++){
		newarr[j]=oldarr[i];j++;
		if((i>0)&&(oldarr[i]==oldarr[i-1])){
			newarr.pop();
			j--;
		}
	}
	$('#supplycards').children(".card").each(function(index,value) {
		$('#' + value.id).fadeTo('fast', 0.2);
	});
	for ( var i in newarr ) {
		$('#supplycards').children(".card-"+newarr[i]).each(function(index,value) {
			$('#' + value.id).draggable({helper: clonehelper});
			$('#' + value.id).fadeTo('fast', 1);
				
		});
	}
}


function changename (name) {
	var message = new nameupdate(name);
	localStorage.setItem('playername', name);	
	ws.send(JSON.stringify(message));
}
function clonehelper () {
	var c = $(this).clone();
	c.width($(this).width());
	c.height($(this).height());
	c.attr('id','tempclonecard');
	return c;
}

function preparehandforbuy() {
	$('#handcards').children(".card").each(function(index,value) {
		$('#' + value.id).draggable("disable");
		$('#' + value.id).removeClass("ui-draggable");
		if(hand[$('#' + value.id).attr("cardnum")].type == 'Treasure') {
			$('#' + value.id).fadeTo('slow', 1);
		} else {
			$('#' + value.id).fadeTo('slow', 0.4);
		}
	});
}

function sendFinishTurn() {
	var message = new finishturn();
	var myJSONText = JSON.stringify(message);
	ws.send(myJSONText);
}

function sendFinishAction () {
	var message = new finishactionphase();
	var myJSONText = JSON.stringify(message);
	ws.send(myJSONText);

}
function hasClass(ele,cls) {
	return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
}
 
function addClass(ele,cls) {
	if (!this.hasClass(ele,cls)) ele.className += " "+cls;
}

function removeClass(ele,cls) {
	if (hasClass(ele,cls)) {
    	var reg = new RegExp('(\\s|^)'+cls+'(\\s|$)');
		ele.className=ele.className.replace(reg,' ');
	}
}

function startbuyphase (com) {
	supplyactive('buy');  //change the colour of the supply;
	gold = com.gold;
	buys = com.buys;
	// UPdate status message with how much gold we have to spend and how many buys are left.
	$("#playstatus").html("Buy phase : Buy = " + buys + ", Gold = " + gold);
	//Add a button that lets a player buy nothing.
	
	var control = document.getElementById('control');
	var skipbuy = document.createElement('div');
	skipbuy.setAttribute("id", "skipBuyContainer");
	skipbuy.innerHTML="<button type='button' id='finishbuy'>Finish Buy Phase Early</button>";
	control.appendChild(skipbuy);
	$('#finishbuy').click(function() {
		//Remove finish Buy button
		document.getElementById('control').removeChild(document.getElementById("skipBuyContainer"));
		showsupply();
		supplydeactivate();
		$("#play").droppable("destroy" );
		sendFinishTurn();
	});
	$('#supplycards').children(".card").each(function(index,value) {
		if(gold >= supply[$('#' + value.id).attr("cardnum")].costgold && supply[$('#' + value.id).attr("cardnum")].available > 0) {
			$('#' + value.id).draggable({helper: clonehelper});
			$('#' + value.id).fadeTo('fast', 1);
		} else {
			$('#' + value.id).fadeTo('slow', 0.2);
		}
		//Figure out if it's sellable.
		//value.draggable({helper:'clone'});
	});
	$("#play").droppable({
        accept: '.card',
        drop: function(event, ui) {
                var c = $(ui.draggable).clone();
                c.removeAttr("id");
				//$("#playedcards").append(c);
                c.removeClass("ui-draggable");
                updateLocalCardPlayed(c,'cardbrought');
                
                //Send a message off that says we just brought a card.
                var message = new buycard(supply[c.attr("cardnum")].name);
            	var myJSONText = JSON.stringify(message);
            	// Send message
            	ws.send(myJSONText); 
            	buys--;
            	gold = gold - supply[c.attr("cardnum")].costgold;
            	$("#playstatus").html("Buy phase : Buy = " + buys + ", Gold = " + gold);
            	if(buys == 0 ) {
            		//Cleanup the supply
            		showsupply();
            		supplydeactivate();
            		//Send finished turn message
            		document.getElementById('control').removeChild(document.getElementById("skipBuyContainer"));
            		$("#play").droppable( "destroy" );
            		sendFinishTurn();
            		
            	} else {
            		//update the status with the buys and gold left..
            		
            		//Update the supply with the new dragable etc.
            		$('#supplycards').children(".card").each(function(index,value) {
        				//Get the id of the supply.
        				if(gold >= supply[$('#' + value.id).attr("cardnum")].costgold) {
        					//$('#' + value.id).draggable({helper:'clone'});
        				} else {
        					
        					$('#' + value.id).draggable("disable");  //cant destroy here, this kills the current drag action!
        					$('#' + value.id).fadeTo('slow', 0.2);
        					
        				}
        				//Figure out if it's sellable.
        				//value.draggable({helper:'clone'});
        			});
            		
            	}
        }
    });
	//<div id="trash" ondrop="drop(this, event)" ondragenter="return false" ondragover="return false"> 
}
function startactionphase(com) {
	handactive('action');
	//Add a button to allow players to skip the action phase if they want to.
	$("#playstatus").html("Action Phase : actions left = " + com.actions);
	var control = document.getElementById('control');
	var skipaction = document.createElement('div');
	skipaction.setAttribute("id", "skipActionContainer");
	skipaction.innerHTML="<button type='button' id='finishbuy'>Finish Action Phase Early</button>";
	control.appendChild(skipaction);
	$('#finishbuy').click(function() {
		//Remove finish Buy button
		document.getElementById('control').removeChild(document.getElementById("skipActionContainer"));
		$("#play").droppable( "destroy" );
		handdeactivate();
		preparehandforbuy();
		sendFinishAction();
	});
	//Make all the action cards dragable
	$('#handcards').children(".card").each(function(index,value) {
		//Get the id of the supply.
		//alert ($('#' + value.id).attr("cardnum"));
		var type = hand[$('#' + value.id).attr("cardnum")].type;
		if(type == 'Action' || type == 'Action/Attack' || type =='Action/Reaction' ) {
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
	//Now set the play area as droppable
	$("#play").droppable({
        accept: '.card', 
        drop: function(event, ui) {
                var card = $(ui.draggable);
                //c.removeAttr("id");
				//$("#playedcards").append(card);
				
				card.draggable("destroy");
				card.attr('style','');  //Jquery seems to leave a bunch of relative references around after dragging with out the clone helper.
            
				updateLocalCardPlayed(card,'actionplayed');
				//Remove the Finish Action Phase early button.
				//Will put it back later if we need it, Don't want someone todo that while the action is being resolved.
				document.getElementById('control').removeChild(document.getElementById("skipActionContainer"));
				//Remove all the dragable stuff currently setup, it may interfer with resolving the action.
				$('#handcards').children(".card").each(function(index,value) {
					$('#' + value.id).draggable("destroy");
				});
				$("#play").droppable( "destroy" );
				handdeactivate();
                //Send a message off that says we just played a card.
                var message = new playcard(hand[card.attr("cardnum")].name,card.attr("cardnum"));
            	//replace the card with a filler
                hand[card.attr("cardnum")]="played";
                var myJSONText = JSON.stringify(message);
            	// Send message
            	ws.send(myJSONText);
            	$("#tempclonecard").remove();
		}
	});
	//$("#handcards").children(".card")
}
window.onload = init;



