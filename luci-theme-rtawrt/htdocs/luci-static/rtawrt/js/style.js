(function ($) {
    var url = self.location.href;

    // Viewport Meta Tag for Apple Devices
    if ((/(iPhone|iPad|iPod|iOS|Mac|Macintosh)/i.test(navigator.userAgent)) && url.indexOf("openclash") != -1) {
        if (!document.querySelector('meta[name="viewport"][content*="viewport-fit=cover"]')) {
            var oMeta = document.createElement('meta');
            oMeta.content = 'width=device-width,initial-scale=1,maximum-scale=1,user-scalable=0,viewport-fit=cover';
            oMeta.name = 'viewport';
            document.getElementsByTagName('head')[0].appendChild(oMeta);
        }
    }

    // DOM Subtree Modification Listener
    var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            var child = document.getElementById("indicators");
            if (child && child.firstElementChild && child.firstElementChild.getAttribute("data-indicator") != "uci-changes") {
                child.firstElementChild.textContent = '\ue6b9';
            }
        });
    });

    var targetNode = document.getElementById("indicators");
    if (targetNode) {
        observer.observe(targetNode, { childList: true, subtree: true });
    }

    // Window Resize Event with Debouncing
    function debounce(func, wait) {
        var timeout;
        return function() {
            var context = this, args = arguments;
            clearTimeout(timeout);
            timeout = setTimeout(function() {
                func.apply(context, args);
            }, wait);
        };
    }

    $(window).resize(debounce(function() {
        if (window.innerWidth <= 992) {
            $("header").css("box-shadow", "0 2px 4px rgb(0 0 0 / 8%)");
        } else {
            $("header").css("box-shadow", "17rem 2px 4px rgb(0 0 0 / 8%)");
        }
    }, 100));
})(jQuery);