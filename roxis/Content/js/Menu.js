$(document).ready(function() {
    CheckIfCookieExists();
});

function CheckIfCookieExists() {
    var c = getCookie("Currency");
    var l = getCookie("lang");

    //check the currency
    //if (c == null) {
    //    setCookie('Currency', "Euro");
    //    $(".setcurrencycookie:contains('Euro')").addClass('topMenuSelected');
    //}
    //else {
    //    $(".setcurrencycookie:contains('" + c + "')").addClass('topMenuSelected');
    //}

    ////check the lang
    //if (l == null) {
    //    setCookie('lang', "Nederlands");
    //    $(".setlangcookie:contains('Nederlands')").addClass('topMenuSelected');
    //}
    //else {
    //    $(".setlangcookie:contains('" + l + "')").addClass('topMenuSelected');
    //}
}

//$(".setcurrencycookie").click(function () {
//    setCookie('Currency', $(this).text());
//    $('.setcurrencycookie').each(function () {
//        $(this).removeClass('topMenuSelected');
//    });
//    $(".setcurrencycookie:contains('" + $(this).text() + "')").addClass('topMenuSelected');
//    window.location.reload(true);
//});

//$(".setlangcookie").click(function () {
//    setCookie('lang', $(this).text());
//    $('.setlangcookie').each(function () {
//        $(this).removeClass('topMenuSelected');
//    });
//    $(".setlangcookie:contains('" + $(this).text() + "')").addClass('topMenuSelected');
//    window.location.reload(true);
//});

function onopen() {
    $("body").css({ overflow: "hidden" });
}

function onclose() {
    $("body").css({ overflow: "inherit" });
}