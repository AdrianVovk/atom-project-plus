{$, ScrollView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
tildify = require 'tildify'
providerManager = require './provider-manager'
util = require './util'
$ = require 'jquery'
URI = 'substance-ide://projects/recent'

module.exports =

  show: () ->
    atom.workspace.open(URI)

  create: (subscriptions) ->
    createView = (state) =>
      providerManager.all().then (result) =>
        return new IntroView(items: util.sortProjects result)

    subscriptions.add atom.deserializers.add
      name: 'ProjectsView'
      deserialize: (state) -> createView(state)

    subscriptions.add atom.workspace.addOpener (filePath) ->
      createView() if filePath is URI


class IntroView extends ScrollView
  @content: (params) ->
    @div class:'project-plus', =>
      @div class:'project-plus-left project-plus-center-vert', =>
        @raw '
          <svg class="project-plus-logo" viewBox="0 0 1280 1280">
            <g id="Hexagon">
              <path d="M1189.3 369.7c0-35.2-20.2-65.6-49.5-80.5L680 23.9v.1c-13.3-7.7-28.8-12.2-45.3-12.2-18.7 0-36.1 5.7-50.6 15.5L125.4 292.1l.4.2C99.4 308 82 336.9 82 369.9v536.3c0 34.3 18.8 64.2 47 79.5L590 1252v-.1c13.3 7.7 28.8 12.2 45.3 12.2 18.7 0 36.1-5.7 50.6-15.5L1137 988.2c30.8-14.4 52-45.6 52-81.9V370h.3v-.3z" fill="#434D65" />
            </g>
            <g id="Tool_Icon" >
              <path d="M697.6 807.6c95.2 1.9 188.2-46.3 239.8-134.1 51.6-87.7 48.5-192.3.7-274.6l-80.8 137.3c-4.6 7.9-12.4 12.8-20.5 12.7l.2.1-125.8-5.5h-.1c-2.6-.4-6.4-1.5-10.3-3.8-4.4-2.6-7.6-6.1-8.7-8.5L627 425.5l.3.2c-.9-1.7-1.9-3.4-2.4-5.3-1.8-6.4-1.4-13.4 2.2-19.6l80.8-137.3c-94.3-1.4-187.8 46.5-239.3 134.2-51.5 87.5-47.9 192.4-.9 274.2L244 1052.1l231.2 133.5 222.4-378z" fill="#E8E8E8" />
            </g>
          </svg>
        '
      @div class: 'project-plus-right project-plus-center-vert', =>
        @tag 'atom-panel', class:'padded', =>
         @div class:'inset-panel', =>
           @div class:'panel-heading', "Project Management"
           @div class:'panel-body', =>
	           @div class:'select-list', =>
	              @ol class:'list-group', style:'max-height:10%', outlet:'list', =>
                  @li class:'padded', =>
                    @div class:'primary-line icon icon-plus', "New Project"
                  @li class:'padded', =>
                    @div class:'primary-line icon icon-git-branch', "Import Remote Git Project"
                  # @li class:'padded', => TODO: Add support for this
                  #   @div class:'primary-line icon icon-file-submodule', "Import from Android Studio"
                  @li class:'padded', click:"openFile",  =>
                    @div class:'primary-line icon icon-file-directory', "Open Project"
        @tag 'atom-panel', class:'padded', =>
         @div class:'inset-panel', =>
           @div class:'panel-heading', "Recent Projects"
           @div class:'panel-body', =>
	           @div class:'select-list', =>
	              @ol class:'list-group', style:'max-height:80%', outlet:'list', =>
                  for item in params.items
	                  @li class:'two-lines padded', click:'openProject', mouseenter:'select', mouseleave:'deselect', =>
                      @div class:'icon icon-x pull-right', click:'deleteProject'
                      @div class:'primary-line', item.title
                      for path in item.paths
                        @div class:'secondary-line', tildify(path)
        @tag 'atom-panel', class:'padded', =>
         @div class:'inset-panel', =>
           @div class:'panel-heading', "Configuration"
           @div class:'panel-body', =>
	           @div class:'select-list', =>
	              @ol class:'list-group', style:'max-height:10%', outlet:'list', =>
                  @li class:'padded', click:'about' , =>
                    @div class:'primary-line icon icon-info', "About"
                  @li class:'padded', click:'settings' , =>
                    @div class:'primary-line icon icon-gear', "Settings"
                  # @li class:'padded', =>
                  #   @div class:'primary-line icon icon-versions', "Check for updates"

  initialize: (params) ->
    @disposables = new CompositeDisposable
    @items = params.items
    @decor(false)
    @disposables.add atom.workspace.onDidChangeActivePaneItem (item) =>
      if @isEqual(item)
        @decor(false)
      else
        $('.tab-bar').show()

  destroy: () ->
    @decor(true)
    @disposables.dispose()

  decor: (show) ->
    if show
      $('.tool-bar').show()
      $('.status-bar').show()
      $('.tab-bar').show()
      console.log 'Project: Decor Reactivated'
    else
      $('.tool-bar').hide()
      $('.status-bar').hide()
      $('.tab-bar').hide()
      console.log 'Project: Decor Hidden'

  selectedItem: (element) ->
    @item = @items[element.index()]

  select: (event, element) ->
    @deselect(event,element)
    element.addClass 'selected'

  deselect: (event, element) ->
    @list.children().removeClass 'selected'

  openProject: (event, element) ->
    @select(event, element)
    @selectedItem(element)

    if atom.config.get('project-manager-ide.newWindow')
      atom.open(pathsToOpen: @item.paths, newWindow: true)
    else
      util.switchToProject(@item)

    setTimeout () =>
      @dispatch('indexer:index') # Start up the indexer
    , 100
    @destroy()

  deleteProject: (event, element) ->
    @select(event, element)
    @selectedItem(element)

    providerManager.remove(@item.paths)

    element.parent().hide(100)

  # Opening other plugins

  dispatch: (command) -> atom.commands.dispatch(atom.views.getView(atom.workspace), command)

  newProject: () -> @dispatch('project:create')

  openFile: () -> @dispatch('project:open')

  about: () -> @dispatch('application:about')

  settings: () -> @dispatch('settings-view:open')

  # Other

  getURI: -> URI

  getTitle: -> "Home"

  isEqual: (other) ->
    other instanceof IntroView
