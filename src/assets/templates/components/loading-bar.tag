loading-bar
  progress.progress.is-primary(max='{ max }', value='{ value }') { value + '%' }
  <progress class="progress is-primary" value="30" max="100">30%</progress>

  script.
    const self = this;
    self.value = 0;
    self.max = 100;
    self.step = 1;
    self.delay = 100;
    self.timer_id = null;
    self.autoplay = false;

    self.on('before-mount', () => {
      if (self.opts.value) self.value = self.opts.value;
      if (self.opts.max) self.max = self.opts.max;
      if (self.opts.step) self.step = self.opts.step;
      if (self.opts.delay) self.delay = self.opts.delay;
      if (self.opts.autoplay) self.autoplay = true;
    });

    self.on('mount', () => {
      if (self.autoplay) self.start();
    });

    self.count = () => {
      self.value += self.step;
    };

    self.start = () => {
      self.timer_id = setInterval(() => {
        self.count();
        self.update();
      }, self.step);
    };

    self.stop = () => {
      if (self.timer_id) {
        clearInterval(self.timer_id);
        self.timer_id = null;
      }
    };
