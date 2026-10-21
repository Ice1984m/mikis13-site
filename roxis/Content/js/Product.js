$(document).ready(function() {

    if ($("#Product_isreview").text() == "True") {
        GoToReview();
    }


    //active zetten van de maat var
    $(".product_maten_cell").click(function() {
        var text = $(this).text();
        $(".product_maten_cell").each(function() {
            if (text == $(this).text()) {
                $(this).removeClass("active");
                $(this).addClass("active");
            } else {
                $(this).removeClass("active");
            }
        });
    });

    //active zetten van de kleur var
    $(".filter-row .kleurondl div span").click(function() {
        //alert("Hit kleur");
        var parent = $(this).parent();
        var parentParent = $(parent).parent();
        var text = $(parentParent).find(".product_color_cellText").text();
        //alert("text = " + text);
        $(".product_color_cellText").each(function() {
            if (text == $(this).text()) {
                $(this).removeClass("active");
                $(this).addClass("active");
            } else {
                $(this).removeClass("active");
            }
        });
    });

    $("#Product_stars_parent").click(function(e) {
        var elementW = $("#Product_stars_parent").width();
        var parentOffset = $(this).parent().offset();
        var x = e.pageX - parentOffset.left;
        var result = parseFloat(parseInt(x, 10) * 100) / parseInt(elementW, 10);

        var nrOfStars = 0;
        if (result < 20) {
            result = elementW / 5;
            nrOfStars = 20;
        } else if (result > 20 && result < 40) {
            result = elementW / 5 * 2;
            nrOfStars = 40;
        } else if (result > 40 && result < 60) {
            result = elementW / 5 * 3;
            nrOfStars = 60;
        } else if (result > 60 && result < 80) {
            result = elementW / 5 * 4;
            nrOfStars = 80;
        } else {
            result = elementW;
            nrOfStars = 100;
        }

        $("#product_stars")
            .css("width", result); //zonder % is het iets minder juist maar beter om hele sterren aan te klikken.
        $("#nrOfStars").val(nrOfStars);
        return false;
    });


}); //end document ready

function GoToReview() {
    $("#Product_tablist1").removeClass("active");
    $("#Product_tablist2").removeClass("active");
    $("#Product_tablist3").addClass("active");
    $("#Product_description").removeClass("active");
    $("#Product_Details").removeClass("active");
    $("#Product_Reviews").addClass("active");
    $("#scrollinproduct").get(0).scrollIntoView();
}