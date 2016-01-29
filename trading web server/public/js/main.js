$(document).ready(function(){
	
	var WinHeight = $('.billboard').height() - 100;
	var BgColor = 'rgba(255, 255, 255, .1)';
	var DarkBgColor = 'rgba(238, 169, 89, .9)';
	
	$(window).scroll(function () {
	    if ($(window).scrollTop() < WinHeight) {
	    	$("header").css("background-color", BgColor);
	    } else {
	    	$("header").css("background-color", DarkBgColor);
	    }
	})

});
