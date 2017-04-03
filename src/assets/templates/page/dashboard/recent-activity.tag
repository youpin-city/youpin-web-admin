dashboard-recent-activity
  div.recent-activity.opaque-bg.content-padding(show='{ comments && comments.length > 0 }')
    b Recent Activity
    //- ul
    //-   li(each="{data}").activity
    //-     .activity-item
    //-       collapsible-content(interactive='false', height='4.5rem', default='collapsed')
    //-         a(href="#!issue-id:{ pin_id }")
    //-           .description { description }
    //-       div.meta-time { timestamp }
    article.media.progress-item.is-block-mobile(each='{ comment, i in comments }')
      //- .media-left
      //-   profile-image.is-round(show='{ comment.type === "comment" }', name='{ comment.user }')
      //-   profile-image.is-round.is-small(show='{ comment.type === "meta" }', name='{ comment.user }')
      .media-content
        .content.pre(style='margin: 0;')
          strong { comment.user }
          | { comment.text }
        div(show='{ comment.annotation }')
          small { comment.annotation }
        .datetime
          small { moment(comment.timestamp).format(app.config.format.datetime_full) }

        //- .comment-staff
        //-   small { comment.user }

      //- .media-right(show='{ comment.photos.length }')
      //-   image-slider-lightbox(data='{ comment.photos }', column='6', highlight='{ false }')


  script.
    let self = this;
    self.data = [];
    self.comments = [];

    api.getRecentActivities( (data) => {
      //- self.data = _.map( data, d => {
      //-   d.timestamp = moment(d.timestamp).fromNow();
      //-   return d;
      //- });
      self.data = data;
      self.calculateComments();
      self.update();
    });

    const _field_term = {
      assigned_department: 'หน่วยงาน',
      assigned_users: 'เจ้าหน้าที่',
      level: 'ความสำคัญ',
      tags: 'แท็ก',
      categories: 'ประเภท',
      neighborhood: 'อาคาร',
      location: 'ตำแหน่งพิน',
      detail: 'ข้อความในรายงาน',
    };

    self.calculateComments = () => {
      function _t(field) {
        return _field_term[field] || field || 'ข้อมูล';
      }
      function parse_acitivity_text(type, action, log) {
        switch (type) {
          case 'ACTION_TYPE/STATE_TRANSITION':
            const state = action.split('/')[1].toLowerCase();
            if (['resolved', 'rejected'].indexOf(state) >= 0) {
              return 'ปิดเรื่องร้องเรียน';
            }
            return 'เปิดเรื่องร้องเรียนใหม่อีกครั้ง';

          case 'ACTION_TYPE/METADATA':
            const prog_index = log.changed_fields.indexOf('progresses');
            if (prog_index >= 0) {
              log.changed_fields.splice(prog_index, 1);
              log.previous_values.splice(prog_index, 1);
              log.updated_values.splice(prog_index, 1);
            }
            if (log.changed_fields.length === 0) {
              return '';
            }
            //- if (log.changed_fields.length === 1 && log.changed_fields[0] === 'progresses)
            return 'แก้ไข ' + _.map(log.changed_fields, field => _t(field)).join(', ');
          default:
            return 'ไม่มีข้อมูล';
        }
      }
      const normalized_activities = self.data.map(item => _.merge(_.clone(item), {
        type: 'meta',
        text: parse_acitivity_text(item.actionType, item.action, item),
        photos: [],
        //- annotation: item.actionType + ' :: ' + item.action,
        //- user: null,
        //- timestamp: item.updated_time
      }));
      self.comments = [].concat(normalized_activities);
      //- if (self.pin) {
      //-   const normalized_comments = _.get(self, 'pin.progresses', []).map(item =>
      //-     _.merge(_.clone(item), {
      //-       type: 'comment',
      //-       text: item.detail,
      //-       photos: [],
      //-       user: null,
      //-       //- annotation: '',
      //-       timestamp: item.updated_time
      //-     })
      //-   );
      //-   self.comments = self.comments.concat(normalized_comments);
      //- }
      self.comments = _.filter(self.comments, comment => comment.text)
      self.comments = _.sortBy(self.comments, c => - new Date(c.timestamp));
      //- console.log(self.comments, 'comments');
    }