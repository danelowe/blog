var m=!1;
(function(d){function w(){return m}function z(){return!0}function k(b){return"string"==typeof b}function p(b){return b.j||(b.j=E++)}function A(b,a,c,d){a=B(a);if(a.e)var e=RegExp("(?:^| )"+a.e.replace(" "," .* ?")+"(?: |$)");return(r[p(b)]||[]).filter(function(b){return b&&(!a.b||b.b==a.b)&&(!a.e||e.test(b.e))&&(!c||p(b.a)===p(c))&&(!d||b.q==d)})}function B(b){b=(""+b).split(".");return{b:b[0],e:b.slice(1).sort().join(" ")}}function C(b,a,c,f,e,n,k){var g=p(b),l=r[g]||(r[g]=[]);a.split(/\s/).forEach(function(a){if("ready"==a)return d(document).L(c);
var h=B(a);h.a=c;h.q=e;h.b in x&&(c=function(b){var a=b.relatedTarget;if(!a||a!==this&&!d.contains(this,a))return h.a.apply(this,arguments)});var g=(h.k=n)||c;h.d=function(a){a=s(a);if(!a.p()){a.data=f;var c=g.apply(b,a.g==q?[a]:[a].concat(a.g));c===m&&(a.preventDefault(),a.stopPropagation());return c}};h.n=l.length;l.push(h);"addEventListener"in b&&b.addEventListener(x[h.b]||t&&u[h.b]||h.b,h.d,h.k&&!t&&h.b in u||!!k)})}function y(b,a,c,d,e){var n=p(b);(a||"").split(/\s/).forEach(function(a){A(b,
a,c,d).forEach(function(a){delete r[n][a.n];"removeEventListener"in b&&b.removeEventListener(x[a.b]||t&&u[a.b]||a.b,a.d,a.k&&!t&&a.b in u||!!e)})})}function s(b,a){if(a||!b.o)if(a||(a=b),d.c(F,function(c,d){var e=a[c];b[c]=function(){this[d]=z;return e&&e.apply(a,arguments)};b[d]=w}),a.defaultPrevented!==q?a.defaultPrevented:"returnValue"in a?a.returnValue===m:a.m&&a.m())b.o=z;return b}function D(b){var a,c={K:b};for(a in b)!G.test(a)&&b[a]!==q&&(c[a]=b[a]);return s(c,b)}var E=1,q,H=Array.prototype.slice,
v=d.z,r={},l={},t="onfocusin"in window,u={focus:"focusin",blur:"focusout"},x={F:"mouseover",G:"mouseout"};l.click=l.D=l.I=l.H="MouseEvents";d.event={add:C,remove:y};d.d=function(b,a){if(v(b)){var c=function(){return b.apply(a,arguments)};c.j=p(b);return c}if(k(a))return d.d(b[a],b);throw new TypeError("expected function");};d.a.bind=function(b,a,c){return this.f(b,a,c)};d.a.M=function(b,a){return this.h(b,a)};d.a.J=function(b,a,c,d){return this.f(b,a,c,d,1)};var G=/^([A-Z]|returnValue$|layer[XY]$)/,
F={preventDefault:"isDefaultPrevented",stopImmediatePropagation:"isImmediatePropagationStopped",stopPropagation:"isPropagationStopped"};d.a.l=function(b,a,c){this.f(a,b,c)};d.a.u=function(b,a,c){this.h(a,b,c)};d.a.B=function(b,a){d(document.body).l(this.r,b,a);return this};d.a.w=function(b,a){d(document.body).u(this.r,b,a);return this};d.a.f=function(b,a,c,f,e){var n,l,g=this;if(b&&!k(b))return d.c(b,function(b,d){g.f(b,a,c,d,e)}),g;!k(a)&&(!v(f)&&f!==m)&&(f=c,c=a,a=q);if(v(c)||c===m)f=c,c=q;f===
m&&(f=w);return g.c(function(k,g){e&&(n=function(a){y(g,a.type,f);return f.apply(this,arguments)});a&&(l=function(b){var c,e=d(b.target).v(a,g).get(0);if(e&&e!==g)return c=d.extend(D(b),{currentTarget:e,C:g}),(n||f).apply(e,[c].concat(H.call(arguments,1)))});C(g,b,f,c,a,l||n)})};d.a.h=function(b,a,c){var f=this;if(b&&!k(b))return d.c(b,function(b,c){f.h(b,a,c)}),f;!k(a)&&(!v(c)&&c!==m)&&(c=a,a=q);c===m&&(c=w);return f.c(function(){y(this,b,c,a)})};d.a.s=function(b){b=k(b)||d.A(b)?d.i(b):s(b);b.g=
void 0;return this.c(function(){"dispatchEvent"in this?this.dispatchEvent(b):d(this).t(b)})};d.a.t=function(b){var a;this.c(function(c,f){a=D(k(b)?d.i(b):b);a.g=void 0;a.target=f;d.c(A(f,b.type||b),function(b,c){c.d(a);if(a.p())return m})})};"focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select keydown keypress keyup error".split(" ").forEach(function(b){d.a[b]=function(a){return a?this.bind(b,a):this.s(b)}});
["focus","blur"].forEach(function(b){d.a[b]=function(a){a?this.bind(b,a):this.c(function(){try{this[b]()}catch(a){}});return this}});d.i=function(b){var a;k(b)||(a=b,b=a.type);var c=document.createEvent(l[b]||"Events"),d=!0;if(a)for(var e in a)"bubbles"==e?d=!!a[e]:c[e]=a[e];c.initEvent(b,d,!0);return s(c)}})(Zepto);
