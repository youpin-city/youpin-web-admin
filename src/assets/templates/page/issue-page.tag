issue-page
  nav.level.is-mobile.is-wrap
    .level-left
      .level-item
        .title เรื่องร้องเรียน
      .level-item
        .control(style='width: 170px; margin-left: 10px;')
          a.waves-effect.waves-light.btn(href='/issue/new')
            i.material-icons.right
              |add
            |สร้างเรื่องใหม่
            
      //- .level-item
      //-   .control(style='width: 140px;')
      //-     input(type='text', id='select_status', ref='select_status', placeholder='แสดงตามสถานะ')

    .level-right
      //- .level-item
      //-   .control(style='width: 140px;')
      //-     input(type='text', id='select_sort', ref='select_sort', placeholder='เรียง')

      //- .level-item
      //-   .control
      //-     .bt-new-issue.right
      //-       a.button.is-accent(href='{ util.site_url("/issue/new") }') สร้างเรื่องร้องเรียน

      .level-item
        a#more-action-menu-btn(href='#')
          i.icon.material-icons more_horiz
        dropdown-menu(target='#more-action-menu-btn', position='bottom right', menu='{ action_menu_list }')

  .level.is-hidden-mobile
    .level-left
      .level-item
        .control(style='width: 140px;')
          label
            |สถานะ
          input(type='text', id='select_status', ref='select_status', placeholder='แสดงตามสถานะ')

      .level-item(show='{ can_sort_by_department }')
        .control(style='width: 140px;')
          label
            |หน่วยงาน
          input(type='text', id='select_department', ref='select_department', placeholder='แสดงตามหน่วยงาน')

      .level-item(show='{ can_sort_by_staff }')
        .control(style='width: 140px;')
          label
            |เจ้าหน้าที่
          input(type='text', id='select_staff', ref='select_staff', placeholder='แสดงตามเจ้าหน้าที่')

      .level-item
        .control(style='width: 140px;')
          label
            |เวลา
          input(type='text', id='select_sort', ref='select_sort', placeholder='เรียง')

    .level-right
      .level-item
        .search-box-wrapper(name='wrapper')
          form(onsubmit='{ submitSearch }')
            .field.has-addons
              .control
                input.input(ref='search_keyword_input', type='text', name='q', value='{ query.q || "" }', placeholder='คำค้น เช่น ทางเท้า', onblur='{ clickToggleSearch }', tabindex='-1')
              .control
                button.button.is-accent 
                  i.material-icons
                    |search

  issue-list

  script.
    const self = this;
    self.can_sort_by_staff = util.check_permission('view_department_issue', user.role);
    self.can_sort_by_department = util.check_permission('view_all_issue', user.role);
    self.query = self.opts.query || {};

    self.action_menu_list = () => {
      const menu = [];
      // create new issue
      if (util.check_permission('create_issue', user.role)) {
        menu.push({
          id: 'action-menu-new-issue-btn',
          name: 'สร้างเรื่องร้องเรียน',
          url: util.site_url('/issue/new'),
          target: '',
        });
      }
      // mark this issue as duplicate
      if (util.check_permission('merge_issue', user.role)) {
        menu.push({
          id: 'action-menu-merge-issue-btn',
          name: 'แจ้งเรื่องซ้ำซ้อน',
          url: util.site_url('/merge'),
          target: '',
        });
      }
      return menu;
    }

    self.current_filter = {
      status: { $in: ['pending', 'assigned', 'processing'] }
    };
    // query keyword ?q=
    if (self.query.q) {
      self.current_filter.detail = { $regex: self.query.q };
    }
    // query staff ?staff=
    if (self.query.staff) {
      const staff = self.query.staff.split(':');
      self.current_filter.assigned_users = staff[0];
    }
    // default sort
    self.current_sort = '-updated_time';

    self.on('before-mount', () => {
      //- self.id = self.opts.dataId;
    });

    self.on('mount', () => {
      //- self.loadPin();
      //- self.bindEvents();
      self.initSelectStatus();
      self.initSelectDepartment();
      self.initSelectStaff();
      self.initSelectSort();

      self.loadPinByFilter();
    });

    self.loadPinByFilter = () => {
      const perm_filter = {};

      if (util.check_permission('view_all_issue', user.role)) {
        // no-op
      } else {
        perm_filter.$or = [];
        if (util.check_permission('view_my_issue', user.role)) {
          perm_filter.$or.push({ owner: user._id });
        }
        if (util.check_permission('view_assigned_issue', user.role)) {
          perm_filter.$or.push({ assigned_users: user._id });
        }
        if (util.check_permission('view_department_issue', user.role)) {
          perm_filter.$or.push({ assigned_department: user.dept._id });
        }
        if (perm_filter.$or.length === 0) delete perm_filter.$or;
      }

      let query = _.merge({}, perm_filter, self.current_filter, {
        $sort: self.current_sort
      });
      self.tags['issue-list'].load(query);
    };

    self.initSelectStatus = () => {
      const status = [
        { id: 'all', name: 'สถานะทั้งหมด' },
        { id: 'open', name: 'เปิด' },
        { id: 'closed', name: 'ปิด' },
        { id: 'resolved', name: 'ปิด (สำเร็จ)' },
        { id: 'rejected', name: 'ปิด (ไม่แก้ไข)' },
        //- { id: 'spam', name: 'ปิดและสเปม' },
        { id: 'featured', name: 'จัดแสดง' }
      ];
      $(self.refs.select_status).selectize({
        maxItems: 1,
        valueField: 'id',
        labelField: 'name',
        //- searchField: 'name',
        options: _.compact(status), // all choices
        items: ['open'], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        //- preload: true,
        onChange: function(value) {
          //- const filter = _.find(status, ['id', value]);
          delete self.current_filter.status;
          delete self.current_filter.closed_reason;
          delete self.current_filter.is_featured;

          switch (value) {
            case 'all':
              break;
            case 'open':
              self.current_filter.status = { $in: ['pending', 'assigned', 'processing'] };
              break;
            case 'closed':
              self.current_filter.status = { $in: ['resolved', 'rejected'] };
              break;
            case 'resolved':
              self.current_filter.status = 'resolved';
              break;
            case 'rejected':
              self.current_filter.status = 'rejected';
              //- self.current_filter.closed_reason = 'rejected';
              break;
            //- case 'spam':
            //-   self.current_filter.status = { $in: ['resolved', 'rejected'] };
            //-   self.current_filter.closed_reason = 'spam';
            //-   break;
            case 'featured':
              self.current_filter.is_featured = true;
              break;
          }

          self.loadPinByFilter();
        }
      });
    }

    self.initSelectDepartment = () => {
      const status = [
        { _id: 'all', name: 'หน่วยงานทั้งหมด' }
      ];
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: _.compact(status), // all choices
        items: ['all'], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        preload: true,
        load: function(query, callback) {
          //- if (!query.length) return callback();
          api.getDepartments({ })
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          delete self.current_filter.assigned_department;
          if (value && value !== 'all') {
            self.current_filter.assigned_department = value;
          }
          self.loadPinByFilter();
        }
      });
    }

    self.initSelectStaff = () => {
      const status = [
        { _id: 'all', name: 'ทั้งหมด' },
        //- { _id: 'empty', name: 'ยังไม่มีเจ้าหน้าที่' }
      ];
      let selected_items = ['all'];
      if (self.query.staff) {
        const staff = self.query.staff.split(':');
        status.push({ _id: staff[0], name: staff[1] });
        selected_items = [staff[0]];
      }
      $(self.refs.select_staff).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: _.compact(status), // all choices
        items: selected_items, // selected choices
        create: false,
        //- allowEmptyOption: false,
        //- hideSelected: true,
        preload: true,
        load: function(query, callback) {
          //- if (!query.length) return callback();
          // @permission
          const perm_filter = {};
          if (util.check_permission([
              'view_all_issue',
              'view_all_staff'
            ], user.role)) {
            //- perm_filter.department = _.get(user, 'dept._id');
          } else if (util.check_permission([
              'view_department_issue',
              'view_department_staff'
            ], user.role)) {
            perm_filter.department = _.get(user, 'dept._id');
          } else {
            perm_filter.not_allow = true;
          }

          api.getUsers(_.merge({}, perm_filter, {
            name: { $regex: query }
          }))
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          delete self.current_filter.assigned_users;
          if (value && value !== 'all') {
            self.current_filter.assigned_users = value;
          }
          self.loadPinByFilter();
        }
      });
    }

    self.initSelectSort= () => {
      const status = [
        { id: '-updated_time', name: 'อัพเดทล่าสุด' },
        { id: 'updated_time', name: 'อัพเดทเก่าสุด' },
        { id: '-created_time', name: 'วันที่รายงานล่าสุด' },
        { id: 'created_time', name: 'วันที่รายงานเก่าสุด' },
        { id: '-level', name: 'ความสำคัญสูง' },
        { id: 'level', name: 'ความสำคัญต่ำ' }
      ];
      $(self.refs.select_sort).selectize({
        maxItems: 1,
        valueField: 'id',
        labelField: 'name',
        options: _.compact(status), // all choices
        items: ['-updated_time'], // selected choices
        create: false,
        allowEmptyOption: false,
        onChange: function(value) {
          self.current_sort = value;
          self.loadPinByFilter();
        }
      });
    }

    self.submitSearch = (e) => {
      e.preventDefault();
      self.current_filter.detail = { $regex: self.refs.search_keyword_input.value };
      self.loadPinByFilter();
    }