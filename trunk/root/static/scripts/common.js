/*
 Kiddman's namespaced convenience functions
*/

var KIDDMAN = function() {

    return {
        
        redirect: function(url) {
            window.location = url;
        },

        redirectToSiteId: function(siteId) {
            KIDDMAN.redirect('/site/' + siteId);
        },

        getPageAttributes: function(siteId, pageId, elemName) {

            var el = document.getElementById(elemName);

            var handleSuccess = function(o) {
                if(o.responseText !== undefined) {
                    el.innerHTML = o.responseText;
                }
            }

            var handleFailure = function(o) {
                if(o.responseText !== undefined) {
                    el.innerHTML = "Boo!";
                }
            }

            var callback = {
                success: handleSuccess,
                failure: handleFailure,
                argument: { }
            };

            var request = YAHOO.util.Connect.asyncRequest(
                'GET', '/site/' + siteId + '/page/' + pageId + '/attributes',
                callback
            );
        }
    }
}();