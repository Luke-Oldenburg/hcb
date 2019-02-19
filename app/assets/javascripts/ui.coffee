$(document).on 'turbolinks:load', ->
  $(document).on 'click', '[data-behavior~=flash]', ->
    $(this).fadeOut 'medium'

  currentFilter = ->
    BK.s('filterbar_item', '[aria-selected=true]').data('name')

  findFilterItem = (name) ->
    BK.s 'filterbar_item', "[data-name=#{name}]"

  activateFilterItem = (name) ->
    BK.deselect 'filterbar_item'
    BK.select 'filterbar_item', "[data-name=#{name}]"

  activateFilterItem 'exists' if BK.thereIs 'filterbar'

  # pass in function for each record
  filterRecords = (valid) ->
    records = BK.s('filterbar_row').hide()
    records.each ->
      $(this).show() if valid(this)
  
  # patch for keyboard accessibility: simulate click on enter key
  $(document).on 'keyup', '[data-behavior~=filterbar_item]', (e) ->
    $(e.target).click() if e.keyCode is 13

  $(document).on 'click', '[data-behavior~=filterbar_item]', ->
    name = $(this).data('name') or 'exists'
    activateFilterItem name
    filterRecords (record) ->
      data = $(record).data('filter')
      data[name] # returns true/false from currentFilter record in data-filter

  $(document).on 'input', '[data-behavior~=filterbar_search]', ->
    activateFilterItem('exists') if currentFilter() isnt 'exists'
    value = $(this).val().toLowerCase()
    filterRecords (record) ->
      $(record).text().toLowerCase().indexOf(value) > -1

  $(document).on 'submit', '[data-behavior~=login]', ->
    val = $('input[name=email]').val()
    localStorage.setItem 'login_email', val

  if BK.thereIs 'login'
    if email = localStorage.getItem 'login_email'
      $('input[type=email]').val email
  
  $(document).on 'change', '[name="invoice[sponsor]"]', (e) ->
    sponsor = $(e.target).children('option:selected').data 'json'
    sponsor ||= {}

    if sponsor.id
      $('[data-behavior~=sponsor_update_warning]').slideDown 'fast'
    else
      $('[data-behavior~=sponsor_update_warning]').slideUp 'fast'

    fields = [
      'name',
      'contact_email',
      'address_line1',
      'address_line2',
      'address_city',
      'address_state',
      'address_postal_code',
      'id'
    ]

    fields.forEach (field) ->
      $("input#invoice_sponsor_attributes_#{field}").val sponsor[field]

  $(document).on 'keydown', '[data-behavior~=autosize]', ->
    t = this
    setTimeout (->
      $(t).attr { rows: Math.floor(t.scrollHeight / 28) }
      $(t).css { height: 'auto' }
    ), 0