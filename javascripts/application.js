
$(document).ready(function() {
	$(".matrix-tile").click(function() {
		$(".indicators", $(this).parent()).toggle();
	});
	$(".indicator").click(function() {
		$(".questions", $(this).parent()).toggle();
	});
	$(".question").click(function() {
		$(".scores", $(this).parent()).toggle();
	});

});