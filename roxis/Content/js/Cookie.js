//https://stackoverflow.com/questions/1458724/how-do-i-set-unset-cookie-with-jquery
function setCookie(key, value) {
    var expires = new Date();
    expires.setTime(expires.getTime() + (1 * 24 * 60 * 60 * 1000));
    document.cookie = key + "=" + value + ";expires=" + expires.toUTCString() + ";path=/";
} //setCookie('test','1');

function getCookie(key) {
    var keyValue = document.cookie.match("(^|;) ?" + key + "=([^;]*)(;|$)");
    return keyValue ? keyValue[2] : null;
} //getCookie('test');


function AddtoCartt(art, img, titel, price, amount, kleurid, maatid, haskleur, hasmaat, userid, login) {
    //if (userid == 0)
    //{
    //    window.location.href = '/account/Login';
    //    return false;
    //}

    var newImgUrl = $("#product-zoom").attr("src");

    var stop = "false";
    var am = $("#product_amount").val();
    if (am == "" || am == 0) {
        am = 1;
    }

    var kleur = $(".product_color_cellText.active").text();
    if (kleur == "" && haskleur == "true") {
        stop = "true";
        $(".lblSelecteerkleur").css("color", "red");
    } else {
        if (haskleur == "true") {
            art += "(" + kleur;
        }

        $(".lblSelecteerkleur").css("color", "black");
    }

    var maat = $(".product_maten_cell.active").text();
    if (maat == "" && hasmaat == "true") {
        stop = "true";
        $(".lblSelecteermaat").css("color", "red");
    } else {
        if (hasmaat == "true") {
            art += "(" + maat;
        }
        $(".lblSelecteermaat").css("color", "black");
    }
    if (hasmaat == "true" && haskleur == "true") {
        kleur += ",";
    }

    if (stop == "true") {
        return false;
    }
    $("#shopanid").addClass("shake");
    var myval = art +
        "&" +
        newImgUrl +
        "&" +
        titel +
        "&" +
        price +
        "&" +
        am +
        "&" +
        kleur +
        "&" +
        maat +
        "&id" +
        userid; //test
    setCookie(art, myval);
    fillCartOnload(userid);

    var delay = 1000;
    setTimeout(function() {
            $("#shopanid").removeClass("shake");
        },
        delay);
    return false;
}

function RemoveFromCart(art, id) {
    document.cookie = art + "=; expires=Thu, 01 Jan 1970 00:00:01 GMT;path=/";
    fillCartOnload(id);
    return false;
}

function fillCartOnload(id) {
    var cart = [];
    $.each(document.cookie.split(/; */),
        function() {
            var splitCookie = this.split("=");
            if (splitCookie[0] != "Currency" &&
                splitCookie[0] != "lang" &&
                splitCookie[0][0] != "_" &&
                splitCookie[0] != "cookieconsent_status" &&
                splitCookie[0][0] == "a") {
                //alert(splitCookie[0]);
                cart.push(splitCookie[1]);
            }
        });

    //$("#inner_test").empty();
    var teller = 0;
    var prijs = 0.0;
    var cartLengt = cart.length;
    for (i = 0; i < cartLengt; i++) {
        var valuArr = cart[i].split("&");
        if (valuArr[7] == "id" + id) //test
        {
            var returnurl = "/Products/Product?productnumber=" + valuArr[0].substr(3).split("(")[0];
            var html = $('<div class="product"><figure><a href="' +
                returnurl +
                '"><img src="' +
                valuArr[1] +
                '" alt="Product"></a></figure><div class="product-meta"><h5 class="product-title"><a href="' +
                returnurl +
                '">' +
                valuArr[2] +
                '</a></h5><div class="product-price-container"><span class="product-price">' +
                GetCurrency() +
                " " +
                parseFloat(valuArr[3].replace(",", ".")).toFixed(2) +
                '</span><span class="product-quantity"> x ' +
                valuArr[4] +
                "</span></div><span>" +
                valuArr[5] +
                " </span><span> " +
                valuArr[6] +
                ' </span></div><a href="#" onclick="RemoveFromCart(\'' +
                valuArr[0] +
                "','" +
                id +
                '\')" class="delete-btn" title="product verwijderen"><i class="fa fa-trash"></i></a></div>');
            $("#inner_test").append(html);
            teller += 1;
            prijs += (parseFloat(valuArr[3].replace(",", ".")) * parseFloat(valuArr[4].replace(",", ".")));
        }
    }
    $(".inner_cart_amount").text(teller);
    $(".inner_cart_tprijs").text(prijs.toFixed(2));
}

//'<div class="product"><figure><a href="#"><img src="'valuArr[1]'" alt="Product"></a></figure><div class="product-meta"><h5 class="product-title"><a href="#">valuArr[2]</a></h5><div class="product-price-container"><span class="product-price">valuArr[3]</span></div><span class="product-quantity">x valuArr[4]</span></div><a href="#" class="delete-btn" title="Delete Product"><i class="fa fa-trash"></i></a></div>'
function GetCurrency() {
    var cur = getCookie("Currency").split("=")[0];
    var curentcur = "";
    if (cur == "Euro") {
        curentcur = "€";
    } else {
        curentcur = "$";
    }
    return curentcur;
}