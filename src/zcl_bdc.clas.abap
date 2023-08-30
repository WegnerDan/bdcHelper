CLASS zcl_bdc DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      ty_bdc_lines     TYPE STANDARD TABLE OF bdcdata WITH DEFAULT KEY,
      ty_bdc_messages  TYPE STANDARD TABLE OF bdcmsgcoll WITH DEFAULT KEY,
      ty_bapi_messages TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY.
    CONSTANTS:

      BEGIN OF c_dismode,
        disp_all TYPE ctu_params-dismode VALUE 'A', " display everything
        err_only TYPE ctu_params-dismode VALUE 'E', " only display errors
        dark     TYPE ctu_params-dismode VALUE 'N', " display nothing
        dbg_dark TYPE ctu_params-dismode VALUE 'P', " display nothing but enable debugging
      END OF c_dismode,
      BEGIN OF c_updmode,
        local TYPE ctu_params-updmode VALUE 'L',
        sync  TYPE ctu_params-updmode VALUE 'S',
        async TYPE ctu_params-updmode VALUE 'A',
      END OF c_updmode,
      BEGIN OF c_cattmode,
        none                 TYPE ctu_params-cattmode VALUE ' ', " No CATT
        no_ind_scr_control   TYPE ctu_params-cattmode VALUE 'N', " CATT without individual screen control
        with_ind_scr_control TYPE ctu_params-cattmode VALUE 'A', " CATT with individual screen control
      END OF c_cattmode,
      BEGIN OF c_okcode,
        " see: https://wiki.scn.sap.com/wiki/display/ABAP/Batch+Input+FAQ#BatchInputFAQ-WhatarethecommandsavailableforcontrollingtheflowofaBIsession?
        delete_transaction TYPE sy-ucomm VALUE '/BDEL', " delete the current transaction from the session
        skip_transaction   TYPE sy-ucomm VALUE '/N',    " skip to the next transaction without completing the current transaction
        cancel_transaction TYPE sy-ucomm VALUE '/BEND', " cancel the processing of the batch input session without completing any additional transactions, including the current transaction.
        switch_to_err_only TYPE sy-ucomm VALUE '/BDE',  " while in foreground mode, use this code to switch to errors only mode
        switch_to_disp_all TYPE sy-ucomm VALUE '/BDA',  " while in errors only mode, use this code to switch to foreground mode
        button_enter       TYPE sy-ucomm VALUE '/00',
        button_f1          TYPE sy-ucomm VALUE '/01',
        button_f2          TYPE sy-ucomm VALUE '/02',
        button_f3          TYPE sy-ucomm VALUE '/03',
        button_f4          TYPE sy-ucomm VALUE '/04',
        button_f5          TYPE sy-ucomm VALUE '/05',
        button_f6          TYPE sy-ucomm VALUE '/06',
        button_f7          TYPE sy-ucomm VALUE '/07',
        button_f8          TYPE sy-ucomm VALUE '/08',
        button_f9          TYPE sy-ucomm VALUE '/09',
        button_f10         TYPE sy-ucomm VALUE '/10',
        button_f11         TYPE sy-ucomm VALUE '/11',
        button_f12         TYPE sy-ucomm VALUE '/12',
      END OF c_okcode.
    CLASS-METHODS:
      conv_bdc_messages_to_bapiret2 IMPORTING bdc_messages  TYPE ty_bdc_messages
                                    RETURNING VALUE(result) TYPE ty_bapi_messages.
    METHODS:
      constructor IMPORTING bdc_lines TYPE ty_bdc_lines OPTIONAL,
      load_queue IMPORTING queue_id            TYPE apqi-qid
                           transaction_counter TYPE apq_tran
                 RAISING   zcx_bdc,
      add_dynpro IMPORTING program TYPE bdcdata-program
                           dynpro  TYPE bdcdata-dynpro,
      add_field IMPORTING name      TYPE bdcdata-fnam
                          value     TYPE any
                          use_write TYPE abap_bool DEFAULT abap_true
                          condense  TYPE abap_bool DEFAULT abap_false,
      add_okcode IMPORTING okcode TYPE sy-ucomm DEFAULT zcl_bdc=>c_okcode-button_enter,
      add_cursor IMPORTING cursor TYPE fnam_____4,
      set_display_mode IMPORTING dismode TYPE ctu_params-dismode DEFAULT zcl_bdc=>c_dismode-err_only
                       RAISING   zcx_bdc,
      set_update_mode IMPORTING updmode TYPE ctu_params-updmode DEFAULT zcl_bdc=>c_updmode-async
                      RAISING   zcx_bdc,
      set_catt_mode IMPORTING cattmode TYPE ctu_params-cattmode
                    RAISING   zcx_bdc,
      set_default_screen_size IMPORTING defsize TYPE abap_bool DEFAULT abap_true,
      set_run_after_commit IMPORTING racommit TYPE abap_bool DEFAULT abap_true,
      set_sy_binpt_to_space IMPORTING nobinpt TYPE abap_bool DEFAULT abap_true,
      set_sy_binpt_to_space_end IMPORTING nobiend TYPE abap_bool DEFAULT abap_true,
      execute IMPORTING tcode TYPE sy-tcode
              RAISING   RESUMABLE(zcx_bdc),
      get_messages RETURNING VALUE(result) TYPE ty_bdc_messages,
      get_bdcdata RETURNING VALUE(result) TYPE ty_bdc_lines,
      set_bdcdata IMPORTING bdc_lines TYPE ty_bdc_lines.
  PROTECTED SECTION.
    DATA:
      bdc_option   TYPE ctu_params,
      bdc_lines    TYPE ty_bdc_lines,
      bdc_messages TYPE ty_bdc_messages.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_bdc IMPLEMENTATION.

  METHOD add_dynpro.
* ---------------------------------------------------------------------
    APPEND VALUE #( program  = program
                    dynpro   = dynpro
                    dynbegin = abap_true ) TO bdc_lines.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD add_field.
* ---------------------------------------------------------------------
    APPEND INITIAL LINE TO bdc_lines ASSIGNING FIELD-SYMBOL(<bdc>).

* ---------------------------------------------------------------------
    <bdc>-fnam = name.

* ---------------------------------------------------------------------
    CASE use_write.
      WHEN abap_true.
        WRITE value TO <bdc>-fval LEFT-JUSTIFIED.
      WHEN abap_false.
        <bdc>-fval = value.
    ENDCASE.

* ---------------------------------------------------------------------
    IF condense = abap_true.
      CONDENSE <bdc>-fval.
    ENDIF.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD execute.
* ---------------------------------------------------------------------
    CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
      EXPORTING
        tcode  = tcode
      EXCEPTIONS
        ok     = 0
        not_ok = 1
        OTHERS = 2.
    CASE sy-subrc.
      WHEN 0.
        FREE bdc_messages.
        CALL TRANSACTION   tcode
             USING         bdc_lines
             OPTIONS FROM  bdc_option
             MESSAGES INTO bdc_messages.
        IF  sy-subrc > 0
        AND sy-subrc < 1001.
          RAISE RESUMABLE EXCEPTION TYPE zcx_bdc
            EXPORTING
              textid      = zcx_bdc=>transaction_error
              syst        = sy
              transaction = tcode.
        ELSEIF sy-subrc > 1000.
          RAISE RESUMABLE EXCEPTION TYPE zcx_bdc
            EXPORTING
              textid = zcx_bdc=>bdc_error.
        ENDIF.
      WHEN OTHERS.
        RAISE RESUMABLE EXCEPTION TYPE zcx_bdc
          EXPORTING
            textid = zcx_bdc=>syst_message
            syst   = sy.
    ENDCASE.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD constructor.
* ---------------------------------------------------------------------
    me->bdc_lines = bdc_lines.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD load_queue.
* ---------------------------------------------------------------------
    CALL FUNCTION 'BDC_OBJECT_READ'
      EXPORTING
        queue_id         = queue_id
        trans            = transaction_counter
      TABLES
        dynprotab        = bdc_lines
      EXCEPTIONS
        not_found        = 1
        system_failure   = 2
        invalid_datatype = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid      = zcx_bdc=>queue_read_error
          queue_id    = queue_id
          trans_count = transaction_counter.
    ENDIF.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD get_bdcdata.
* ---------------------------------------------------------------------
    result = bdc_lines.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD add_okcode.
* ---------------------------------------------------------------------
    APPEND VALUE #( fnam = 'BDC_OKCODE'
                    fval = okcode    ) TO bdc_lines.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD add_cursor.
* ---------------------------------------------------------------------
    APPEND VALUE #( fnam = 'BDC_CURSOR'
                    fval = cursor    ) TO bdc_lines.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_bdcdata.
* ---------------------------------------------------------------------
    me->bdc_lines = bdc_lines.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_display_mode.
* ---------------------------------------------------------------------
    IF dismode NA c_dismode.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid  = zcx_bdc=>invalid_dismode
          dismode = dismode.
    ENDIF.

* ---------------------------------------------------------------------
    bdc_option-dismode = dismode.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_update_mode.
* ---------------------------------------------------------------------
    IF updmode NA c_updmode.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid  = zcx_bdc=>invalid_updmode
          updmode = updmode.
    ENDIF.

* ---------------------------------------------------------------------
    bdc_option-updmode = updmode.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_catt_mode.
* ---------------------------------------------------------------------
    IF cattmode NA c_cattmode.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid   = zcx_bdc=>invalid_cattmode
          cattmode = cattmode.
    ENDIF.

* ---------------------------------------------------------------------
    bdc_option-cattmode = cattmode.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_default_screen_size.
* ---------------------------------------------------------------------
    bdc_option-defsize = defsize.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_sy_binpt_to_space_end.
* ---------------------------------------------------------------------
    bdc_option-nobiend = nobiend.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_sy_binpt_to_space.
* ---------------------------------------------------------------------
    bdc_option-nobinpt = nobinpt.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_run_after_commit.
* ---------------------------------------------------------------------
    bdc_option-racommit = racommit.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD get_messages.
* ---------------------------------------------------------------------
    result = bdc_messages.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD conv_bdc_messages_to_bapiret2.
* ---------------------------------------------------------------------
    result = CORRESPONDING #( bdc_messages MAPPING type       = msgtyp
                                                   id         = msgid
                                                   number     = msgnr
                                                   message_v1 = msgv1
                                                   message_v2 = msgv2
                                                   message_v3 = msgv3
                                                   message_v4 = msgv4 ).

* ---------------------------------------------------------------------
  ENDMETHOD.

ENDCLASS.
