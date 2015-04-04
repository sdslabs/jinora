var favicon= new Favico({ // creating a favico instance
    animation : 'popFade', 
    bgColor : '#d00',
    textColor: '#fff', 
    fontFamily : 'Arial',
    fontStyle : 'bold',

  });


// name of the hidden property and the change event for visibility
var hidden, visibilityChange; 
if (typeof document.hidden !== "undefined") { // Opera 12.10 and Firefox 18 and later support 
  hidden = "hidden";
  visibilityChange = "visibilitychange";
} else if (typeof document.mozHidden !== "undefined") {
  hidden = "mozHidden";
  visibilityChange = "mozvisibilitychange";
} else if (typeof document.msHidden !== "undefined") {
  hidden = "msHidden";
  visibilityChange = "msvisibilitychange";
} else if (typeof document.webkitHidden !== "undefined") {
  hidden = "webkitHidden";
  visibilityChange = "webkitvisibilitychange";
}
 
var count =0;
function handleVisibilityChange() {
  if (document[hidden]) {
    //handled in polymer.coffee
  } else {
    favicon.reset();
  }

}

//whenever the page is hidden call updateCount
function updateCount(){
  count++;
  //document.title="New Messages("+ count+")";  
  favicon.badge(count);
}


// if browser doesn't support addEventListener or the Page Visibility API
if (typeof document.addEventListener === "undefined" || 
  typeof document[hidden] === "undefined") {
  alert("Page Visibility API is not supported.");
} else {
  // page visibility change  gets handeled 
  document.addEventListener(visibilityChange, handleVisibilityChange, false);
    
};


