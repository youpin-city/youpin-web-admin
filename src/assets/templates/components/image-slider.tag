
image-slider
  .slider-list
    //- yield items with 'slider-item' class
    #{'yield'}

  //-.image-fullscreen-modal
  //-  include ../jade/components/photoswipe

  script.
    var self = this;
    self.item = opts.item || 'div';
    self.image = opts.image !== 'false'; // image item or full div element
    self.viewer = opts.viewer === 'true'; // default: false
    self.arrows = !(opts.arrows === 'false'); // default: true
    self.dots = opts.dots === 'true'; // default: false
    self.autoplay = !(opts.autoplay === 'false'); // default: true
    self.autoplay_speed = +(opts.autoplaySpeed || 12000); // default: 4000
    self.fade = !(opts.fade === 'false'); // default: true
    // self.lazyload = !(opts.lazyload === 'false'); // default: true
    // self.lazyloaded = false;
    // self.retina = opts.retina === 'true'; // default: false
    // slide item image/bg classes
    self.extendClass = [];
    // if (self.lazyload) self.extendClass.push('lazyload');
    // if (self.retina) self.extendClass.push('retina');
    self.extendClass = self.extendClass.join(' ');

    // openPhotoSwipe() {
    //   var pswpElement = $(self.$fullscreen).find('.pswp')[0];

    //   // build items array
    //   var items = $(self.root).find('.slider-item:not(.slick-cloned)').map(function(index, el) {
    //     var $item = $(this);
    //     // var $image = $item.find('.image');
    //     return {
    //       src: $item.attr('data-src'),
    //       w: $item.attr('data-width'),
    //       h: $item.attr('data-height')
    //     };
    //   });

    //   var options = {
    //     modal: false,
    //     index: self.$slider.slick('slickCurrentSlide') // start at first slide
    //   };

    //   // Initializes and opens PhotoSwipe
    //   var gallery = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items, options);
    //   gallery.init();
    //   gallery.listen('afterChange', function() {
    //     // go to slide without animation
    //     self.$slider.slick('slickGoTo', this.getCurrentIndex(), true);
    //   });
    // }

    self.on('mount', function() {
      // // attach modal at the end of body tag
      // self.$fullscreen = $(self.root).find('.image-fullscreen-modal');
      // self.$fullscreen.appendTo('body');

      // make slider
      self.$slider = $(self.root).find('.slider-list');
      // show all immediate children
      self.$slider.children().show();
      self.$slider
      .on('init reinit', function(e) {
        if (self.image) {
          $(this).find('.slider-item').each(function() {
            var $item = $(this);
            var src = $item.attr('data-src');
            if (!src) {
              src = /url\(['"]?([^'"]*)['"]?\)/gi.exec($item.css('background-image'))[1];
            }
            $item.empty();
            if (self.item === 'img') {
              $item.append($('<img/>').addClass(self.extendClass).attr('data-src', src));
            } else {
              $item.append($('<div class="image hide-on-error"/>').addClass(self.extendClass)
                .attr('data-src', src)
                .css('background-image', 'url(\'' + src + '\')')
              );
            }
          });
        }
      })
      .on('setPosition', function(e, slick) {
        if (self.lazyload) {
          var i = slick.currentSlide;
          i = [ i === 0 ? slick.$slides.length-1 : i-1,
                i,
                i === slick.$slides.length-1 ? 0 : i+1
              ];
          var elements = _.compact($(slick.$slides[i[0]]).add(slick.$slides[i[1]]).add(slick.$slides[i[2]])
            .find('.lazyload:not(.lazyloaded)').toArray());
          // if (elements.length > 0) app.blazy.load(elements, true);
        }
      })
      .slick({
        infinite: true,
        speed: self.fade ? 1200 : 1200,
        fade: self.fade,
        autoplay: self.autoplay,
        autoplaySpeed: self.autoplay_speed,
        arrows: self.arrows,
        dots: self.dots,
        cssEase: 'ease-in'
      });

      // open lightbox on click
      if (self.viewer) {
        // TODO: enable lightbox after fixing undefined image dimension problem
        // $(self.root).find('.slider-item').on('click', self.openPhotoSwipe);
      }
    });
