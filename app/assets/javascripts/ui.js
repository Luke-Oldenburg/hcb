const whenViewed = (element, callback) => new IntersectionObserver(([entry]) => entry.isIntersecting && callback(), { threshold: 1 }).observe(element);
const loadModals = element => {
  $(element).on('click', '[data-behavior~=modal_trigger]', function (e) {
    const controlOrCommandClick = e.ctrlKey || e.metaKey;
    if ($(this).attr('href') || $(e.target).attr('href')) {
      if (controlOrCommandClick) return;
      e.preventDefault()
      e.stopPropagation()
    }
    BK.s('modal', '#' + $(this).data('modal')).modal({
      modalClass: $(this).parents('turbo-frame').length
        ? 'turbo-frame-modal'
        : undefined,
      closeExisting: false
    })
    return this.blur()
  })

  $(element).on('click', '[data-behavior~=modal_trigger] [data-behavior~=modal_ignore]', function (e) {
    e.stopPropagation();
    e.preventDefault()
  });
}

// restore previous theme setting
$(document).ready(function () {
  if (
    document.querySelector('html').getAttribute('data-ignore-theme') == null &&
    BK.isDark()
  ) {
    BK.s('toggle_theme').find('svg').toggle()
    return BK.styleDark(true)
  }
})

$(document).on('click', '[data-behavior~=flash]', function () {
  $(this).fadeOut('medium')
})

loadModals(document);
(() => {
  let autoModals = $('[data-modal-auto-open~=true]')

  if (autoModals.length < 1) return;

  let element = autoModals.first();

  BK.s('modal', '#' + $(element).data('modal')).modal({
    modalClass: $(element).parents('turbo-frame').length
      ? 'turbo-frame-modal'
      : undefined,
    closeExisting: false
  })
})();

$(document).on('keyup', 'action', function (e) {
  if (e.keyCode === 13) {
    return $(e.target).click()
  }
})

$(document).on('submit', '[data-behavior~=login]', function () {
  const val = $('input[name=email]').val()
  return localStorage.setItem('login_email', val)
})

$(document).on('change', '[name="invoice[sponsor]"]', function (e) {
  let sponsor = $(e.target).children('option:selected').data('json')
  if (!sponsor) {
    sponsor = {}
  }

  if (sponsor.id) {
    $('[data-behavior~=sponsor_update_warning]').slideDown('fast')
  } else {
    $('[data-behavior~=sponsor_update_warning]').slideUp('fast')
  }

  const fields = [
    'name',
    'contact_email',
    'address_line1',
    'address_line2',
    'address_city',
    'address_state',
    'address_postal_code',
    'address_country',
    'id'
  ]

  return fields.forEach(field =>
    $(`#invoice_sponsor_attributes_${field}`).val(sponsor[field])
  )
})

$(document).on('change', '[name="check[lob_address]"]', function (e) {
  let lob_address = $(e.target).children('option:selected').data('json')
  if (!lob_address) {
    lob_address = {}
  }

  if (lob_address.id) {
    $('[data-behavior~=lob_address_update_warning]').slideDown('fast')
  } else {
    $('[data-behavior~=lob_address_update_warning]').slideUp('fast')
  }

  const fields = ['name', 'address1', 'address2', 'city', 'state', 'zip', 'id']

  return fields.forEach(field =>
    $(`input#check_lob_address_attributes_${field}`)
      .val(lob_address[field])
      .change()
  )
})

const updateAmountPreview = function () {
  const amount = $('[name="invoice[item_amount]"]').val().replace(/,/g, '')
  const previousAmount = BK.s('amount-preview').data('amount') || 0
  if (amount === previousAmount) {
    return
  }
  if (amount > 0) {
    const feePercent = BK.s('amount-preview').data('fee')
    const lFeePercent = (feePercent * 100).toFixed(1)
    const lAmount = BK.money(amount * 100)
    const feeAmount = BK.money(feePercent * amount * 100)
    const revenue = BK.money((1 - feePercent) * amount * 100)
    BK.s('amount-preview').text(
      `${lAmount} - ${feeAmount} (${lFeePercent}% fiscal sponsorship fee) = ${revenue}`
    )
    BK.s('amount-preview').show()
    return BK.s('amount-preview').data('amount', amount)
  } else {
    BK.s('amount-preview').hide()
    return BK.s('amount-preview').data('amount', 0)
  }
}

$(document).on('input', '[name="invoice[item_amount]"]', () =>
  updateAmountPreview()
)

$(document).on(
  'click',
  '[data-behavior~=transaction_dedupe_info_trigger]',
  e => {
    const raw = $(e.target).closest('tr').data('json')
    const json = JSON.stringify(raw, null, 2)
    BK.s('transaction_dedupe_info_target').html(json)
  }
)

$(document).on('click', function (e) {
  if ($(e.target).data('behavior')?.includes('menu_input')) return

  const o = $(BK.openMenuSelector)
  const c = $(e.target).closest('[data-behavior~=menu_toggle]')
  if (o.length > 0 || c.length > 0) {
    BK.toggleMenu(o.length > 0 ? o : c)
    e.stopImmediatePropagation()
  }
})
$(document).keydown(function (e) {
  // Close popover menus on esc
  if (e.keyCode === 27 && $(BK.openMenuSelector).length > 0) {
    return BK.toggleMenu($(BK.openMenuSelector))
  }
})

$(document).on('click', '[data-behavior~=toggle_theme]', () => BK.toggleDark())

$(document).on('turbo:load', function () {
  if (window.location !== window.parent.location) {
    $('[data-behavior~=hide_iframe]').hide()
  }

  $('[data-behavior~=select_content]').on('click', e => e.target.select())

  BK.s('autohide').hide()

  $.each(BK.s('async_frame'), (i, frame) => {
    const loadFrame = () => {
      $.get($(frame).data('src'), data => {
        const parent = $(frame).parent()
        $(frame).replaceWith(data)
        loadModals(parent)
      }).fail(() => {
        $(frame).children('.shimmer').first().addClass('shimmer--error')
      })
    }

    if ($(frame).data('loading') == "lazy") {
      whenViewed(frame, loadFrame);
    } else loadFrame();
  })

  if (BK.thereIs('login')) {
    let email
    const val = $('input[name=email]').val()

    // auto-fill email address from local storage
    if (val === '' || val === undefined) {
      try {
        if ((email = localStorage.getItem('login_email'))) {
          BK.s('login').find('input[type=email]').val(email)
        }
      } catch (e) { }
    }

    // auto fill @hackclub.com email addresses on submit
    BK.s('login').submit(e => {
      const val = $('input[name=email]').val()
      // input must end with '@h'
      if (val.endsWith('@h')) {
        const fullEmail = val.match(/^(.*)@h$/)[1] + '@hackclub.com'
        BK.s('login').find('input[type=email]').val(fullEmail)
      }
    })
  }

  // login code sanitization
  $(document).on('keyup change', "input[name='login_code']", function () {
    const currentVal = $(this).val()
    let newVal = currentVal.replace(/[^0-9]+/g, '')

    // truncate if more than 6 digits
    if (newVal.length >= 6 + 6) {
      newVal = newVal.slice(-6)
    } else if (newVal.length > 6) {
      newVal = newVal.substring(0, 6)
    }

    // split code into two groups of three digits; separated with a dash
    if (newVal.length > 3) {
      newVal = newVal.slice(0, 3) + '-' + newVal.slice(3)
    }

    // Allow a dash to be typed as the 4th character
    if (currentVal.at(3) === '-' && currentVal.length === 4) {
      newVal += '-'
    }

    $(this).val(newVal)
  })

  // if you add the money behavior to an input, it'll add commas, only allow two numbers for cents,
  // and only permit numbers to be entered
  $('input[data-behavior~=money]').on('input', function () {
    let value = $(this)
      .val()
      .replace(/,/g, '') // replace all commas with nothing
      .replace(/[^0-9.]+/g, '') // replace anything that isn't a number or a dot with nothing
      .replace(/\B(?=(\d{3})+(?!\d))/g, ',') // put commas into the number (pulled off of stack overflow)

    let removeExtraCents

    if (value.lastIndexOf('.') != -1) {
      let cents = value.substring(value.lastIndexOf('.'), value.length)
      cents = cents
        .replace(/[\.\,]/g, '')
        .substring(0, cents.length > 2 ? 2 : 1)

      removeExtraCents =
        value.substring(0, value.lastIndexOf('.')) + '.' + cents
    } else {
      removeExtraCents = value
    }

    $(this).val(removeExtraCents)
  })

  $('input[data-behavior~=prevent_whitespace]').on({
    keydown: function (e) {
      if (e.which === 32) return false
    },
    change: function () {
      this.value = this.value.replace(/\s/g, '')
    }
  })

  $('textarea:not([data-behavior~=no_autosize])')
    .each(function () {
      $(this).css({
        height: `${this.scrollHeight + 1}px`
      })
    })
    .on('input', function () {
      this.style.height = 'auto'
      this.style.height = this.scrollHeight + 1 + 'px'
    })

  // Popover menus
  BK.openMenuSelector = '[data-behavior~=menu_toggle][aria-expanded=true]'
  BK.toggleMenu = function (m) {
    // The menu content might either be a child or a sibling of the button.
    $(m).find('[data-behavior~=menu_content]').slideToggle(100)
    $(m).siblings('[data-behavior~=menu_content]').slideToggle(100)

    const o = $(m).attr('aria-expanded') === 'true'
    if (o) {
      // The menu is closing
      // Clear all inputs in the menu
      $(m)
        .siblings('[data-behavior~=menu_content]')
        .find('input[data-behavior~=menu_input')
        .val('')
    } else {
      // The menu is opening
      // Autofocus any inputs that should be autofocused
      $(m)
        .siblings('[data-behavior~=menu_content]')
        .find('input[data-behavior~=menu_input--autofocus')
        .focus()
    }
    return $(m).attr('aria-expanded', !o)
  }

  if (BK.thereIs('shipping_address_inputs')) {
    const shippingInputs = BK.s('shipping_address_inputs')
    const physicalInput = $('#stripe_card_card_type_physical')
    const virtualInput = $('#stripe_card_card_type_virtual')
    $(physicalInput).on('change', e => {
      if (e.target.checked) shippingInputs.slideDown()
    })
    $(virtualInput).on('change', e => {
      if (e.target.checked) shippingInputs.slideUp()
    })
  }
  
  if (BK.s('reimbursement_report_create_form_type_selection').length) {
    const dropdownInput = $('#reimbursement_report_user_email')
    const emailInput = $('#reimbursement_report_email')
    const maxInput = $('#reimbursement_report_maximum_amount_wrapper')
    const inviteInput = $('#reimbursement_report_invite_message_wrapper')

    const forMyselfInput = $('#reimbursement_report_for_myself')
    const forOrganizerInput = $('#reimbursement_report_for_organizer')
    const forExternalInput = $('#reimbursement_report_for_external')

    dropdownInput.hide()
    emailInput.hide()
    maxInput.hide()
    inviteInput.hide()

    $(forMyselfInput).on('change', e => {
      if (e.target.checked) {
        dropdownInput.slideUp()
        emailInput.slideUp()
        maxInput.slideUp()
        inviteInput.slideUp()
        emailInput.val(emailInput[0].attributes["value"].value)
      }
    })
    
    $(forOrganizerInput).on('change', e => {
      if (e.target.checked) {
        emailInput.val(dropdownInput.val())
        dropdownInput.slideDown()
        emailInput.slideUp()
        maxInput.slideDown()
        inviteInput.slideUp()
      }
    })
    
    $(forExternalInput).on('change', e => {
      if (e.target.checked) {
        emailInput.val("")
        dropdownInput.slideUp()
        emailInput.slideDown()
        maxInput.slideDown()
        inviteInput.slideDown()
      }
    })
    
    $(dropdownInput).on('change', e => {
      emailInput.val(e.target.value)
    })
  }

  $('[data-behavior~=mention]').on('click', e => {
    BK.s('comment').val(`${BK.s('comment').val() + (BK.s('comment').val().length > 0 ? " " : "")}${e.target.dataset.mentionValue || e.target.innerText}`)
    BK.s('comment')[0].scrollIntoView();
  })  

  if (BK.thereIs('additional_transparency_settings')) {
    const additionalTransparencySettings = BK.s(
      'additional_transparency_settings'
    )
    const transparencyToggle = $('#event_is_public')
    $(transparencyToggle).on('change', e => {
      if (e.target.checked) {
        // When transparency mode is enabled, also enable indexing by default
        $('#event_is_indexable').prop('checked', true)

        additionalTransparencySettings.slideDown()
      } else {
        additionalTransparencySettings.slideUp()
      }
    })
  }

  const tiltElement = $('[data-behavior~=hover_tilt]')
  const enableTilt = () =>
    tiltElement.tilt({
      maxTilt: 15,
      speed: 400,
      perspective: 1500,
      glare: true,
      maxGlare: 0.25,
      scale: 1.0625
    })
  const disableTilt = () => tiltElement.tilt.destroy.call(tiltElement)
  const setTilt = function () {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      return disableTilt()
    } else {
      return enableTilt()
    }
  }
  setTilt()
  return window
    .matchMedia('(prefers-reduced-motion: reduce)')
    .addListener(() => setTilt())
})

$(document).on('turbo:frame-load', function () {
  if (BK.thereIs('check_payout_method_inputs') && BK.thereIs('ach_transfer_payout_method_inputs')) {
    const checkPayoutMethodInputs = BK.s('check_payout_method_inputs')
    const achTransferPayoutMethodInputs = BK.s('ach_transfer_payout_method_inputs')
    $(document).on("change", "#user_payout_method_type_userpayoutmethodcheck", e => {
      if (e.target.checked) checkPayoutMethodInputs.slideDown() && achTransferPayoutMethodInputs.slideUp()
    })
    $(document).on("change", "#user_payout_method_type_userpayoutmethodachtransfer", e => {
      if (e.target.checked) achTransferPayoutMethodInputs.slideDown() && checkPayoutMethodInputs.slideUp()
    })
  }
})

$('[data-behavior~=ctrl_enter_submit]').keydown(function (event) {
  if ((event.ctrlKey || event.metaKey) && event.keyCode === 13) {
    $(this).closest('form').get(0).requestSubmit()
  }
})

function hidePWAPrompt() {
  document.body.classList.add("hide__pwa__prompt")
}

$(document).on('click', '[data-behavior~=expand_receipt]', function (e) {
  const controlOrCommandClick = e.ctrlKey || e.metaKey;
  if ($(this).attr('href') || $(e.target).attr('href')) {
    if (controlOrCommandClick) return;
    e.preventDefault()
    e.stopPropagation()
  }
  $(e.target).parents(".modal--popover").addClass("modal--popover--receipt-expanded");
  let selected_receipt = document.querySelectorAll(`.hidden_except_${e.originalEvent.target.dataset.receiptId}`)[0]
  selected_receipt.style.display = "flex";
  selected_receipt.style.setProperty("--receipt-size", "100%");
  selected_receipt.classList.add("receipt--expanded")
})

function unexpandReceipt() {
  document.querySelectorAll(`.receipt--expanded`)[0]?.classList?.remove('receipt--expanded');
  document.querySelector('.modal--popover.modal--popover--receipt-expanded')?.classList?.remove('modal--popover--receipt-expanded');
}

document.addEventListener("turbo:load", () => {
  if (window.self === window.top) {
    document.body.classList.remove('embedded');
  }
})

document.addEventListener("turbo:before-stream-render", ((event) => {
  const fallbackToDefaultActions = event.detail.render
  event.detail.render = function (streamElement) {
    if (streamElement.action == "refresh_link_modals") {
      const turboStreamElements = document.querySelectorAll('turbo-frame');
      turboStreamElements.forEach(element => {
        if (element.id.startsWith('link_modal')) {
          element.innerHTML = "<strong>Loading...</strong>"
          element.reload();
        }
      });
    } else {
      fallbackToDefaultActions(streamElement)
    }
  }
}))

let hankIndex = 0
$(document).on('keydown', function (e) {
  if (e.originalEvent.key === 'hank'[hankIndex]) {
    hankIndex++
    if (hankIndex === 4) {
      return $('[name="header-logo"]').attr('src', '/hank.png')
    }
  } else {
    return (hankIndex = 0)
  }
})

// Disable scrolling on <input type="number" /> elements
$(document).on("wheel", "input[type=number]", e => {
  e.preventDefault()
  e.target.blur()
})
