
$(document).ready(function() {
	$(".matrix-title").click(function() {
		$(".matrix-content", $(this).parent()).toggle();
		return false;
	});
	$(".indicator-title").click(function() {
		$(".indicator-content", $(this).parent()).toggle();
		return false;
	});
	$(".question-title").click(function() {
		$(".question-content", $(this).parent()).toggle();
		return false;
	});
	$("h4").click(function() {
		var next = $(this).next();
		next.toggle();
		$(this).html(next.is(":visible") ? "verberg individuele scores" : "toon individuele scores")
		return false;
	});
	$(".tab a").click(function() {
		var href = $(this).attr("href").substr(1);
		$(".detail_tab", $(this).parent().parent().parent()).hide();
		$("#" + href).show();
		$("li", $(this).parent().parent()).removeClass("selected");
		$(this).parent().addClass("selected");
		return false;
	});

});