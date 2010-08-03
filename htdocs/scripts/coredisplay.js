//Draw the current hand in the #hand area
function showhand() {
	if(gameover) {
		return;
	}
	//Make sure there are no cards in the hand area to start with
	$('#handcards').html('');
	for ( var i in hand )
	{
		if(hand[i] != 'played') {
			var carddiv = document.createElement('img');
			carddiv.setAttribute("id", "handcard" + i);
			carddiv.setAttribute("class", "card card-"+hand[i].name);
			carddiv.setAttribute("src", "./images/"+hand[i].image);
			carddiv.setAttribute("cardnum",i);
			//document.getElementById('handcards').appendChild(carddiv);
			
			var alink = document.createElement('a');
			alink.setAttribute("href", "./images/"+hand[i].image);
			document.getElementById('handcards').appendChild(alink);
			alink.appendChild(carddiv);
		}
	}
	$('#handcards a').flyout();
}
//Draw the new supply supply
function shownewsupply() {
	if(gameover) {
		return;
	}
	$('#supplycards').html('');
	//We get an array of cards, lets display them
	for ( var i in supply )
	{
		if(supply[i].available <= 0) {
			//we Have Run out of this card...
			//Show an empty card instead.
			var carddiv = document.createElement('img');
			carddiv.setAttribute("id", "supplycard-" + supply[i].name);
			carddiv.setAttribute("class", "card supply card-empty");
			carddiv.setAttribute("cardnum",i);
			carddiv.setAttribute("cardname",supply[i].name);
			carddiv.setAttribute("src", "./images/empty.jpg");
			document.getElementById('supplycards').appendChild(carddiv);
		} else {
			var carddiv = document.createElement('img');
			carddiv.setAttribute("id", "supplycard-" + supply[i].name);
			carddiv.setAttribute("class", "card supply card-" + supply[i].name);
			carddiv.setAttribute("cardnum",i);
			carddiv.setAttribute("cardname",supply[i].name);
			carddiv.setAttribute("src", "./images/"+supply[i].image);
			var alink = document.createElement('a');
			alink.setAttribute("href", "./images/"+supply[i].image);
			document.getElementById('supplycards').appendChild(alink);
			alink.appendChild(carddiv);
		}
		var countdiv = document.createElement('div');
		countdiv.innerHTML=supply[i].available;
		countdiv.setAttribute("class", "cardcount");
		countdiv.setAttribute("id","supplycount-" + supply[i].name);
		document.getElementById('supplycards').appendChild(countdiv);
		
	}
	$('#supplycards a').flyout();
}

//Draw the new supply supply
//This is intended of more of an refresh supply
//Update any depleted cards
//Remove any draggables
//Remove any fade effects in place
function showsupply() {
	$('#supplycards .card').each(function(index,value) {
		$(value).fadeTo('fast', 1);
		$(value).draggable('destroy');
		//Look for this card in the supply
		var found = -1;
		for ( var i in supply )
		{
			if(supply[i].name == $(value).attr('cardname')) {
				found = i;
			}
		}
		if( found != -1) {
			//update the card count
			$('#supplycount-'+supply[found].name).html(+supply[found].available);
		} else {
			//The card wasn't found, must have been removed from the supply
			$(value).attr('src','./images/empty.jpg');
			$(value).attr("cardnum",-1);
			$(value).next().html(0);
		}
	});
	$('#supplycards a').flyout();
}
//Called when the supply is active and the player is able to drag cards out
function supplyactive(action) {
	$('#supply').addClass(action);
}

function supplydeactivate() {
	$('#supply').removeClass();
}
//Called when the players hand is active and they are able to drag carsd out.
function handactive(action) {
	$('#hand').addClass(action);
}

function handdeactivate() {
	$('#hand').removeClass();
}

function trashactive(action) {
	$('#trash').addClass(action);
}

function trashdeactivate() {
	$('#trash').removeClass();
}
function discardactive(action) {
	$('#discard').addClass(action);
}

function discarddeactivate() {
	$('#discard').removeClass();
}


//When the play area gets to many cards in it, remove the oldest group of cards.
function prunePlayArea() {
	
	 c = $('#playedcards').get(0);
     c.scrollLeft = c.scrollWidth;
     
	//Figure out how many cards are in the play area.
	if(c.scrollLeft != 0) {
	//if($("#playedcards .card").size() > 6 ) {
		//If there is only one area, because someone has played _lots_ of cards this turn, lets just trim that a little
		if($("#playedcards .playareaupdate").size()==1) {
			$("#playedcards a").first().fadeTo('slow', 0, function() { $(this).remove();});
		} else {
			//Get the first child and remove it.
			$("#playedcards a").first().parent().fadeTo('slow', 0, function() { $(this).remove();});
		}
	}
}
//A card has been played by another player.
//Make a card div, and chuck it in the player area
function updateCardPlayed(playerid,card,actiontype,name) {
	
	//Create a card html object first
	var carddiv = document.createElement('img');
	carddiv.setAttribute("class", "card  card-" + card.name);
	carddiv.setAttribute("src", "./images/"+card.image);
	carddiv.setAttribute("src", "./images/"+card.image);
	//carddiv.setAttribute("style", "max-width:" + $('#supplycard-Copper').width());
	//alert($('#supplycard-Copper').width());
	//TODO problem here.
	//
	$(carddiv).width( $('#supplycard-Copper').width());
	$(carddiv).height( $('#supplycard-Copper').height());
	var alink = document.createElement('a');
	alink.setAttribute("href", "./images/"+card.image);
	
	//Figure out if the last area was played for the same player for the same reason
	if(lastPlayUpdate == "" + playerid + actiontype +actioncount && document.getElementById(lastPlayUpdate) != null) {
		//append the card to  this div
		$("#" + lastPlayUpdate).append(alink);
		alink.appendChild(carddiv);
		
	} else {
		//create a new div and put the card in that.
		lastPlayUpdate ="" + playerid + actiontype +actioncount;
		var actiondiv = document.createElement('div');
		actiondiv.setAttribute("id", lastPlayUpdate);
		actiondiv.setAttribute("class", "playareaupdate play-" + actiontype );
		
		switch(actiontype)
		{
		case 'cardbrought':
			actiondiv.innerHTML = "<h4>" + name + "'s buys.</h4>";
			break;
		case 'actionplayed':
			actiondiv.innerHTML = "<h4>" + name + "'s actions.</h4>";
			break;
		case 'witchresolve':
			actiondiv.innerHTML = "<h4>" + name + "'s witch res.</h4>";
			break;
		case 'bureaucratresolve':
			actiondiv.innerHTML = "<h4>" + name + "'s bureaucrat res.</h4>";
			break;
		case 'Militiaresolve':
			actiondiv.innerHTML = "<h4>" + name + "'s militia res.</h4>";
			break;
		case 'Trash':
			actiondiv.innerHTML = "<h4>" + name + " trashed.</h4>";
			break;
		case 'Discard':
			actiondiv.innerHTML = "<h4>" + name + " discarded.</h4>";
			break;
		}
		actiondiv.appendChild(alink);
		alink.appendChild(carddiv);
		document.getElementById('playedcards').appendChild(actiondiv);
	}
	$(alink).flyout();
	prunePlayArea();
	
}
//The local player played a card, whe have been based a html card object, so append it to the local play area.
function updateLocalCardPlayed(card,actiontype) {
	
	
	card.width( $('#supplycard-Copper').width());
	card.removeAttr("id");
	
	var alink = document.createElement('a');
	alink.setAttribute("href", card.attr('src'));
	
	//Figure out if the last area was played for the same player for the same reason
	
	if($('.playareaupdate').size() != 0 && $('.playareaupdate').last().attr("id") ==  "" + "Your" + actiontype+actioncount) {
		$("#" + lastPlayUpdate).append(alink);
	} else {
		actioncount++;
		//create a new div and put the card in that.
		lastPlayUpdate = "" + "Your" + actiontype+actioncount;
		var actiondiv = document.createElement('div');
		actiondiv.setAttribute("id", lastPlayUpdate);
		actiondiv.setAttribute("class", "playareaupdate play-" + actiontype );
		switch(actiontype)
		{
		case 'cardbrought':
			actiondiv.innerHTML = "<h4>Your buys.</h4>";
			break;
		case 'actionplayed':
			actiondiv.innerHTML = "<h4>Your actions.</h4>";
			break;
		case 'witchresolve':
			actiondiv.innerHTML = "<h4>Your witch resolution.</h4>";
			break;
		case 'bureaucratresolve':
			actiondiv.innerHTML = "<h4>Your bureaucrat res.</h4>";
			break;
		case 'Militiaresolve':
			actiondiv.innerHTML = "<h4>Your militia res.</h4>";
			break;
		case 'Trash':
			actiondiv.innerHTML = "<h4>You trashed.</h4>";
			break;
		case 'Discard':
			actiondiv.innerHTML = "<h4>You discarded.</h4>";
			break;
		}
		document.getElementById('playedcards').appendChild(actiondiv);
		$("#" + lastPlayUpdate).append(alink);
	}
	$(alink).append(card);
	$(alink).flyout();
	prunePlayArea();
}
