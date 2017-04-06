issue-create-page
  .container
    nav.level.is-mobile.is-wrap
      .level-left.content-padding
        .level-item
          .issue-title.title
            i.icon.material-icons announcement
            | สร้างเรื่องร้องเรียน

    .section
      .columns
        //- .column.is-3
        //-   .issue-photos
        //-     div
        //-       div No photo

        .issue-edit-info.column.is-12
          .issue-detail
            .field
              label รายละเอียด
              .control
                textarea.textarea(ref='description_input', placeholder='รายละเอียดปัญหาหรือข้อเสนอแนะที่ถูกรายงานเข้ามา')
          hr
          .issue-more-detail.columns
            .column.is-6
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th สถานที่
                    td
                      .field
                        .control
                          input.input(ref='neighborhood_input', type='text', value='{ _.get(pin, "neighborhood.0", "") }', placeholder='ตึก ห้อง')
                      .field
                        .control
                          input.input(ref='location_lat_input', type='text', value='{ _.get(pin, "location.coordinates.0", "") }', placeholder='lat')
                      .field
                        .control
                          input.input(ref='location_long_input', type='text', value='{ _.get(pin, "location.coordinates.1", "") }', placeholder='long')
            .column.is-6
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th ประเภท
                    td
                      .field
                        .control
                          input(type='text', id='select_categories', ref='select_categories', placeholder='เลือกประเภท')
                  tr
                    th แท็ก
                    td
                      .field
                        .control
                          input(type='text', id='select_tags', ref='select_tags', placeholder='เลือกแท็ก')
          hr
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(class='{ "is-disabled": saving_info }', href='{ util.site_url(\'/issue\') }') ยกเลิก
            .control
              a.button.is-outlined.is-accent(class='{ "is-loading": saving_info }', onclick='{ updateIssueInfo }') สร้าง

  script.
    const self = this;
    self.saving_info = false;

    self.on('mount', () => {
      self.initSelectCategory();
      self.initSelectTag();
      //- self.initSelectPriority();
    });

    self.initSelectCategory = () => {
      const select = self.refs.select_categories;
      const cat_list = app.get('issue.categories') || [];
      //- const selected_cat_list = self.pin.categories || [];
      $(select).selectize({
        maxItems: 3,
        valueField: 'id',
        labelField: 'name',
        options: cat_list, // all choices
        //- items: selected_cat_list, // selected choices
        create: false
      });
    }

    self.initSelectTag = () => {
      const select = self.refs.select_tags;
      //- const select = $(self.root).find('#select_tags').get(0); //self.refs.select_tags;
      //- const tag_list = self.pin.tags.map(tag => ({ id: tag, name: tag }));
      $(select).selectize({
        valueField: 'id',
        labelField: 'name',
        //- options: tag_list, // all choices
        //- items: _.map(tag_list, 'id'), // selected choices
        create: true,
        render: {
          option_create: function(data, escape) {
            return '<div class="create">เพิ่ม <strong>' + escape(data.input) + '</strong></div>';
          }
        }
      });
    }

    self.updateIssueInfo = (e) => {
      const pin_location = self.refs.location_lat_input.value && self.refs.location_long_input.value
      ? {
        type: 'Point',
        coordinates: [
          self.refs.location_lat_input.value,
          self.refs.location_long_input.value
        ]
      } : null;
      const update = {
        provider: user._id,
        owner: user._id,
        organization: _.get(app, 'config.organization.id'),
        detail: self.refs.description_input.value,
        photos: [],
        level: '2', // normal
        categories: _.compact(self.refs.select_categories.value.split(',')).map(cat => _.trim(cat)),
        tags: _.compact(self.refs.select_tags.value.split(',')).map(tag => _.trim(tag)),
        neighborhood: _.compact([self.refs.neighborhood_input.value]),
        location: pin_location
      }
      self.saving_info = true;
      api.createPin(update)
      .then(response => {
        location.href = util.site_url('/issue/' + response._id);
      })
      .catch(err => {
        Materialize.toast(err.message, 8000, 'dialog-error large')
      })
      .then(() => {
        self.saving_info = false;
        self.update();
      });
    };
