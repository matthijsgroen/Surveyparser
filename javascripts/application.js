
$(document).ready(function() {
	$(".matrix-title").click(function() {
		$(".matrix-content", $(this).parent()).toggle();
	});
	$(".indicator-title").click(function() {
		$(".indicator-content", $(this).parent()).toggle();
	});
	$(".question-title").click(function() {
		$(".question-content", $(this).parent()).toggle();
	});
	$("h4").click(function() {
		var next = $(this).next();
		next.toggle();
		$(this).html(next.is(":visible") ? "verberg individuele scores" : "toon individuele scores")
	});

});