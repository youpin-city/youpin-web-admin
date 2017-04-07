merge-page
  .container
    nav.level.is-mobile.is-wrap
      .level-left
        .level-item
          .title แจ้งเรื่องซ้ำซ้อน
      .level-right
        .level-item
          .control
            button.merge-issue-btn.button(class='{ "is-loading": saving_merge_pin, "is-disabled": !(pin && parent_pin), "is-accent": pin && parent_pin }', onclick="{ commitMerge }")
              | ปิดและรวมกับเรื่องหลัก
    .full-container
      .field
        label.section-title
          i.icon.material-icons.is-small content_copy
          span เรื่องที่ซ้ำซ้อน
        .control
          input(type='text', id='select_child_pin', ref='select_child_pin', placeholder='เลือกเรื่องร้องเรียนที่ซ้ำซ้อน')

      .field
        .has-text-centered(style='margin: 1rem 0;')
          i.icon.material-icons arrow_downward

      .field
        label.section-title
          i.icon.material-icons.is-small next_week
          span นำไปรวมกับเรื่องหลัก
        .control
          input(type='text', id='select_parent_pin', ref='select_parent_pin', placeholder='เลือกเรื่องร้องเรียนหลัก')


    .spacing
    nav.level.is-mobile.is-wrap
      .level-left
      .level-right
        .level-item
          .control
            button.merge-issue-btn.button(class='{ "is-loading": saving_merge_pin, "is-disabled": !(pin && parent_pin), "is-accent": pin && parent_pin }', onclick="{ commitMerge }")
              | ปิดและรวมกับเรื่องหลัก

  script.
    let self = this;
    self.id = self.opts.id;
    self.pin = null;
    self.parent_pin = null;
    self.saving_merge_pin = false;

    //- self.opposite = {
    //-   'select_child_pin': 'select_parent_pin',
    //-   'select_parent_pin': 'select_child_pin'
    //- };

    self.on('mount', () => {
      loadPin()
      .then(pin => {
        self.initSelectIssue('pin', 'select_child_pin', {
          query: (this_selectize) => ({ status: 'pending' }),
          onChange: (this_selectize) => {
            const selectize = self.refs['select_parent_pin'].selectize;
            selectize.removeOption(this_selectize.getValue());
          }
        });
        self.initSelectIssue('parent_pin', 'select_parent_pin', {
          query: (this_selectize) => ({ status: 'pending' }),
          onChange: (this_selectize) => {
            const selectize = self.refs['select_child_pin'].selectize;
            selectize.removeOption(this_selectize.getValue());
          }
        });
      });
    });

    function loadPin () {
      return api.getPin(self.id)
      .then(data => {
        self.pin = data;
        self.update();
        return self.pin;
      });
    }

    self.commitMerge = function(e) {
      e.preventDefault();
      if (!self.pin) {
        Materialize.toast('ต้องเลือกเรื่องซ้ำซ้อน', 8000, 'dialog-error large');
        return;
      }
      if (!self.parent_pin) {
        Materialize.toast('ต้องเลือกเรื่องหลัก', 8000, 'dialog-error large');
        return;
      }

      self.saving_merge_pin = false;
      self.update();
      api.mergePins(self.pin._id, self.parent_pin._id)
      .then(response => {
        if (!response.ok) {
          Materialize.toast('Error: ' + resposne.statusText, 8000, 'dialog-error large');
          return;
        }
        const update_status = { state: 'resolved' };
        const update_pin = { closed_reason: 'duplicate' };
        return api.postTransition(self.pin._id, update_status)
        .then(() => api.patchPin(self.pin._id, update_pin))
        .then(() => {
          location.href = '/issue/' + self.parent_pin._id;
        })
        .catch(err => {
          Materialize.toast('Error: ' + resposne.statusText, 8000, 'dialog-error large');
        });
      })
      .then(() => {
        self.saving_merge_pin = true;
        self.update();
      });
    };

    self.initSelectIssue = (data_path, ref_name, opts = {}) => {
      function mount_issue($root, getValue = (el, i) => i) {
        const mount = (i, el) => {
          if (!el._tag) {
            let value;
            if (typeof getValue === 'function') {
              value = getValue.bind(this)(el, i);
            } else {
              value = getValue;
            }
            riot.mount(el, 'issue-item', { item: this.options[value] });
          }
        };
        $root.find('issue-item').each(mount.bind(this));
      }
      const selected_item = _.get(self, data_path);
      $(self.refs[ref_name]).selectize({
        //- plugins: ['remove_button'],
        maxItems: 1,
        valueField: '_id',
        labelField: 'detail',
        searchField: 'detail',
        options: _.compact([selected_item]),
        items: selected_item ? [selected_item._id] : [],
        //- options: _.compact([assigned_dept]), // all choices
        //- items: assigned_dept ? [assigned_dept._id] : [], // selected choices
        create: false,
        hideSelected: true,
        preload: true,
        onDropdownOpen: function($dropdown) {
          mount_issue.call(this, $dropdown, (el, i) => $(el).data('value'));
        },
        render: {
          option: function (item, escape) {
            return '<issue-item class="is-compact is-small is-plain"></issue-item>';
          },
          item: function (item, escape) {
            return '<issue-item class="is-plain"></issue-item>';
          }
        },
        load: (query, callback) => {
          //- if (!query.length) return callback();
          let queryOpts;
          if (typeof opts.query === 'function') {
            queryOpts = opts.query.call(this, self);
          } else {
            queryOpts = _.merge({}, opts.query);
          }

          api.getPins(_.merge({
            detail: { $regex: query },
            is_merged: { $ne: true },
          }, queryOpts))
          .then(result => {
            callback(result.data);
          });
        },
        onInitialize: function () {
          const value = this.getValue();
          if (value) {
            mount_issue.call(this, this.$control, value);
          }
          if (typeof opts.onInitialize === 'function') {
            opts.onInitialize.call(this, this);
          }
        },
        onChange: function (value) {
          mount_issue.call(this, this.$control, value);
          _.set(self, data_path, this.options[value]);
          if (typeof opts.onChange === 'function') {
            opts.onChange.call(this, this);
          }
          self.update();
        }
      });
    }
