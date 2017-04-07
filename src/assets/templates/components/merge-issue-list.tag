merge-issue-list
  div(class="{ 'list-view': true }")
    ul.issue-list(if='{ pins.length > 0 }')
      li.issue.clearfix(each="{ p in pins }")
        .issue-select
          .input-field
            input(type='radio', id='select-issue-{ p._id }', name='selected_issue', value='{ p._id }', onchange='{ checkSelectedRadio }')
            label(for='select-issue-{ p._id }')
        .issue-img
          div.img.responsive-img(style='background-image: url("{ _.get(p.photos, "0") }");')
          //- img.issue-img(src="http://lorempixel.com/150/150/city/")

          div.issue-id
            label ID
            span(href='#manage-issue-modal' data-id='{ p._id }') { p._id.slice(-10) }

        div.issue-body
          div.issue-desc
            //- b Description
            div { p.detail }

          footer
            div.meta.issue-location
              i.icon.material-icons.tiny location_on
              span
                a.bubble(if='{ p.location && p.location.coordinates }', href='#')
                  | See map
                span.bubble(if='{ p.location_name }') { p.location_name }
            div.meta.issue-category(if='{ p.categories && p.categories.length > 0 }')
              i.icon.material-icons.tiny turned_in_not
              span
                span.bubble(each="{ cat in p.categories }") { cat }
            div.meta.issue-tags(if='{ p.tags && p.tags.length > 0 }')
              i.icon.material-icons.tiny label
              span
                span.bubble(each="{ tag in p.tags }") { tag }
        div.issue-info
          div
            label Status
            span.big-text { p.status }

          div
            label Dept.
            span.big-text { p.assigned_department ? p.assigned_department.name : '-' }

          div.meta(if='{p.owner}', title="assigned to")
            i.icon.material-icons.tiny face
            | { p.owner.name }

          div.meta(title="created at")
            i.icon.material-icons.tiny access_time
            | { moment(p.created_time).fromNow() }
            //- | [date& time]

    div(if='{ pins.length === 0 }')
      .spacing-large
      .center
        i.icon.material-icons.large location_off
        h5 No issue

      .spacing-large

    div.load-more-wrapper
      a.load-more(class="{active: hasMore}", onclick="{loadMore()}" ) Load More


  script.
    let self = this;

    this.pins = [];
    this.hasMore = true;

    this.load = (opts) => {
        self.currentQueryOpts = opts;

        api.getPins(opts).then( res => {
          self.pins = res.data;
          self.updateHasMoreButton(res);
          self.update();
        });
    }

    this.loadMore = () => {
      return () => {
        let opts = _.extend( {}, self.currentQueryOpts, { '$skip': self.pins.length });
        api.getPins(opts).then( res => {
          self.pins = self.pins.concat(res.data)
          self.updateHasMoreButton(res);
          self.update();
        });
      };
    }

    this.updateHasMoreButton = (res) => {
        self.hasMore = ( res.total - ( res.skip + res.data.length ) ) > 0
    }

    this.on('mount', () => {
    });

    this.checkSelectedRadio = (e) => {
      self.trigger('select-issue', $('[name="selected_issue"]:checked').val());
    };
