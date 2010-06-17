
$(document).ready(function() {
	$(".matrix-tile").click(function() {
		$(".indicators", $(this).parent()).toggle();
	});
	$(".indicator").click(function() {
		$(".questions", $(this).parent()).toggle();
	});
	$(".question").click(function() {
		$(".statistics", $(this).parent()).toggle();
	});
	$("h4").click(function() {
		var next = $(this).next();
		next.toggle();
		$(this).html(next.is(":visible") ? "verberg individuele scores" : "toon individuele scores")
	});

});