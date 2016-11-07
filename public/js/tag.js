'use strict';

riot.tag2('image-slider', '<div class="slider-list"> <yield></yield> </div>', '', '', function (opts) {
  var self = this;
  self.item = opts.item || 'div';
  self.image = opts.image !== 'false';
  self.viewer = opts.viewer === 'true';
  self.arrows = !(opts.arrows === 'false');
  self.dots = opts.dots === 'true';
  self.autoplay = !(opts.autoplay === 'false');
  self.autoplay_speed = +(opts.autoplaySpeed || 12000);
  self.fade = !(opts.fade === 'false');

  self.extendClass = [];

  self.extendClass = self.extendClass.join(' ');

  self.on('mount', function () {

    self.$slider = $(self.root).find('.slider-list');

    self.$slider.children().show();
    self.$slider.on('init reinit', function (e) {
      if (self.image) {
        $(this).find('.slider-item').each(function () {
          var $item = $(this);
          var src = $item.attr('data-src');
          if (!src) {
            src = /url\(['"]?([^'"]*)['"]?\)/gi.exec($item.css('background-image'))[1];
          }
          $item.empty();
          if (self.item === 'img') {
            $item.append($('<img/>').addClass(self.extendClass).attr('data-src', src));
          } else {
            $item.append($('<div class="image hide-on-error"/>').addClass(self.extendClass).attr('data-src', src).css('background-image', 'url(\'' + src + '\')'));
          }
        });
      }
    }).on('setPosition', function (e, slick) {
      if (self.lazyload) {
        var i = slick.currentSlide;
        i = [i === 0 ? slick.$slides.length - 1 : i - 1, i, i === slick.$slides.length - 1 ? 0 : i + 1];
        var elements = _.compact($(slick.$slides[i[0]]).add(slick.$slides[i[1]]).add(slick.$slides[i[2]]).find('.lazyload:not(.lazyloaded)').toArray());
      }
    }).slick({
      infinite: true,
      speed: self.fade ? 1200 : 1200,
      fade: self.fade,
      autoplay: self.autoplay,
      autoplaySpeed: self.autoplay_speed,
      arrows: self.arrows,
      dots: self.dots,
      cssEase: 'ease-in'
    });

    if (self.viewer) {}
  });
});

riot.tag2('preloader', '<div class="preloader-wrapper active {class}"> <div class="spinner-layer spinner-blue-only"> <div class="circle-clipper left"> <div class="circle"></div> </div> <div class="gap-patch"> <div class="circle"></div> </div> <div class="circle-clipper right"> <div class="circle"></div> </div> </div> </div>', '', '', function (opts) {
  var self = this;
  self.class = opts.class;
});

riot.tag2('search-box', '<a class="toggle-btn" href="#" onclick="{clickToggleSearch}"><i class="icon material-icons">search</i></a> <div class="search-box-wrapper" name="wrapper"> <form onsubmit="{submitSearch}"> <input class="flat" type="search" name="q" placeholder="{placeholder}" onblur="{clickToggleSearch}" tabindex="-1"> </form> </div>', 'search-box,[riot-tag="search-box"],[data-is="search-box"]{ display: inline-block; } search-box .toggle-btn,[riot-tag="search-box"] .toggle-btn,[data-is="search-box"] .toggle-btn{ display: inline-block; opacity: 1; transition: all 0.2s ease-out; } search-box .search-box-wrapper,[riot-tag="search-box"] .search-box-wrapper,[data-is="search-box"] .search-box-wrapper{ display: inline-block; width: 0; opacity: 0; padding-left: 0; padding-right: 0; transition: all 0.2s ease-out; } search-box.open .toggle-btn,[riot-tag="search-box"].open .toggle-btn,[data-is="search-box"].open .toggle-btn{ width: 0; opacity: 0; padding-left: 0; padding-right: 0; } search-box.open .search-box-wrapper,[riot-tag="search-box"].open .search-box-wrapper,[data-is="search-box"].open .search-box-wrapper{ width: 200px; opacity: 1; padding-left: 1rem; padding-right: 1rem; }', 'class="{open: open}"', function (opts) {
  var self = this;
  self.open = false;
  self.path = opts.path || '';
  self.placeholder = opts.placeholder;

  self.on('updated', function () {
    if (self.open) {
      $(self.q).focus();
    } else {}
  });

  self.clickToggleSearch = function (e) {
    e.preventDefault();
    self.open = !self.open;
    $('body')[self.open ? 'addClass' : 'removeClass']('global-search-active');
  };

  self.submitSearch = function (e) {
    e.preventDefault();
    location.href = util.site_url(self.path, {
      q: self.q.value
    });
  };
});
