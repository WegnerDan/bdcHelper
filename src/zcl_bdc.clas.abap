CLASS zcl_bdc DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      mty_t_bdcdata    TYPE STANDARD TABLE OF bdcdata WITH DEFAULT KEY,
      mty_t_bdcmsgcoll TYPE STANDARD TABLE OF bdcmsgcoll WITH DEFAULT KEY,
      mty_t_bapiret2   TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY.
    CONSTANTS:
      BEGIN OF mc_dismode,
        disp_all TYPE ctu_params-dismode VALUE 'A', " display everything
        err_only TYPE ctu_params-dismode VALUE 'E', " only display errors
        dark     TYPE ctu_params-dismode VALUE 'N', " display nothing
        dbg_dark TYPE ctu_params-dismode VALUE 'P', " display nothing but enable debugging
      END OF mc_dismode,
      BEGIN OF mc_updmode,
        local TYPE ctu_params-updmode VALUE 'L',
        sync  TYPE ctu_params-updmode VALUE 'S',
        async TYPE ctu_params-updmode VALUE 'A',
      END OF mc_updmode,
      BEGIN OF mc_cattmode,
        none                 TYPE ctu_params-cattmode VALUE ' ', " No CATT
        no_ind_scr_control   TYPE ctu_params-cattmode VALUE 'N', " CATT without individual screen control
        with_ind_scr_control TYPE ctu_params-cattmode VALUE 'A', " CATT with individual screen control
      END OF mc_cattmode,
      BEGIN OF mc_okcode,
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
      END OF mc_okcode.
    CLASS-METHODS:
      conv_bdc_messages_to_bapiret2 IMPORTING it_bdc_msg         TYPE mty_t_bdcmsgcoll
                                    RETURNING VALUE(rt_bapi_msg) TYPE mty_t_bapiret2.
    METHODS:
      constructor IMPORTING it_bdcdata TYPE mty_t_bdcdata OPTIONAL,
      load_queue IMPORTING iv_qid   TYPE apqi-qid
                           iv_trans TYPE apq_tran
                 RAISING   zcx_bdc,
      add_dynpro IMPORTING iv_program TYPE bdcdata-program
                           iv_dynpro  TYPE bdcdata-dynpro,
      add_field IMPORTING iv_name      TYPE bdcdata-fnam
                          iv_value     TYPE any
                          iv_use_write TYPE abap_bool DEFAULT abap_true
                          iv_condense  TYPE abap_bool DEFAULT abap_false,
      add_okcode IMPORTING iv_okcode TYPE sy-ucomm DEFAULT zcl_bdc=>mc_okcode-button_enter,
      add_cursor IMPORTING iv_cursor TYPE fnam_____4,
      set_display_mode IMPORTING iv TYPE ctu_params-dismode DEFAULT zcl_bdc=>mc_dismode-err_only
                       RAISING   zcx_bdc,
      set_update_mode IMPORTING iv TYPE ctu_params-updmode
                      RAISING   zcx_bdc,
      set_catt_mode IMPORTING iv TYPE ctu_params-cattmode
                    RAISING   zcx_bdc,
      set_default_screen_size IMPORTING iv TYPE abap_bool DEFAULT abap_true,
      set_run_after_commit IMPORTING iv TYPE abap_bool DEFAULT abap_true,
      set_sy_binpt_to_space IMPORTING iv TYPE abap_bool DEFAULT abap_true,
      set_sy_binpt_to_space_end IMPORTING iv TYPE abap_bool DEFAULT abap_true,
      execute IMPORTING iv_tcode TYPE sy-tcode
              RAISING   RESUMABLE(zcx_bdc),
      get_messages RETURNING VALUE(rt) TYPE mty_t_bdcmsgcoll,
      get_bdcdata RETURNING VALUE(rt_bdcdata) TYPE mty_t_bdcdata,
      set_bdcdata IMPORTING it_bdcdata TYPE mty_t_bdcdata.
  PROTECTED SECTION.
    DATA:
      ms_options  TYPE ctu_params,
      mt_bdcdata  TYPE mty_t_bdcdata,
      mt_messages TYPE mty_t_bdcmsgcoll.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_bdc IMPLEMENTATION.

  METHOD add_dynpro.
* ---------------------------------------------------------------------
    APPEND VALUE #( program  = iv_program
                    dynpro   = iv_dynpro
                    dynbegin = abap_true  ) TO mt_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD add_field.
* ---------------------------------------------------------------------
    APPEND INITIAL LINE TO mt_bdcdata ASSIGNING FIELD-SYMBOL(<ls_bdc>).

* ---------------------------------------------------------------------
    <ls_bdc>-fnam = iv_name.

* ---------------------------------------------------------------------
    CASE iv_use_write.
      WHEN abap_true.
        WRITE iv_value TO <ls_bdc>-fval LEFT-JUSTIFIED.
      WHEN abap_false.
        <ls_bdc>-fval = iv_value.
    ENDCASE.

* ---------------------------------------------------------------------
    IF iv_condense = abap_true.
      CONDENSE <ls_bdc>-fval.
    ENDIF.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD execute.
* ---------------------------------------------------------------------
    CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
      EXPORTING
        tcode  = iv_tcode
      EXCEPTIONS
        ok     = 0
        not_ok = 1
        OTHERS = 2.
    CASE sy-subrc.
      WHEN 0.
        FREE mt_messages.
        CALL TRANSACTION   iv_tcode
             USING         mt_bdcdata
             OPTIONS FROM  ms_options
             MESSAGES INTO mt_messages.
        IF  sy-subrc > 0
        AND sy-subrc < 1001.
          RAISE RESUMABLE EXCEPTION TYPE zcx_bdc
            EXPORTING
              textid      = zcx_bdc=>transaction_error
              syst        = sy
              transaction = iv_tcode.
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
    mt_bdcdata = it_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD load_queue.
* ---------------------------------------------------------------------
    CALL FUNCTION 'BDC_OBJECT_READ'
      EXPORTING
        queue_id         = iv_qid
        trans            = iv_trans
      TABLES
        dynprotab        = mt_bdcdata
      EXCEPTIONS
        not_found        = 1
        system_failure   = 2
        invalid_datatype = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid      = zcx_bdc=>queue_read_error
          queue_id    = iv_qid
          trans_count = iv_trans.
    ENDIF.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD get_bdcdata.
* ---------------------------------------------------------------------
    rt_bdcdata = mt_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD add_okcode.
* ---------------------------------------------------------------------
    APPEND VALUE #( fnam = 'BDC_OKCODE'
                    fval = iv_okcode    ) TO mt_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD add_cursor.
* ---------------------------------------------------------------------
    APPEND VALUE #( fnam = 'BDC_CURSOR'
                    fval = iv_cursor    ) TO mt_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_bdcdata.
* ---------------------------------------------------------------------
    mt_bdcdata = it_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_display_mode.
* ---------------------------------------------------------------------
    IF iv NA mc_dismode.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid  = zcx_bdc=>invalid_dismode
          dismode = iv.
    ENDIF.

* ---------------------------------------------------------------------
    ms_options-dismode = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_update_mode.
* ---------------------------------------------------------------------
    IF iv NA mc_updmode.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid  = zcx_bdc=>invalid_updmode
          updmode = iv.
    ENDIF.

* ---------------------------------------------------------------------
    ms_options-updmode = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_catt_mode.
* ---------------------------------------------------------------------
    IF iv NA mc_cattmode.
      RAISE EXCEPTION TYPE zcx_bdc
        EXPORTING
          textid   = zcx_bdc=>invalid_cattmode
          cattmode = iv.
    ENDIF.

* ---------------------------------------------------------------------
    ms_options-cattmode = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_default_screen_size.
* ---------------------------------------------------------------------
    ms_options-defsize = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_sy_binpt_to_space_end.
* ---------------------------------------------------------------------
    ms_options-nobiend = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_sy_binpt_to_space.
* ---------------------------------------------------------------------
    ms_options-nobinpt = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD set_run_after_commit.
* ---------------------------------------------------------------------
    ms_options-racommit = iv.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD get_messages.
* ---------------------------------------------------------------------
    rt = mt_messages.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD conv_bdc_messages_to_bapiret2.
* ---------------------------------------------------------------------
    rt_bapi_msg = CORRESPONDING #( it_bdc_msg MAPPING type       = msgtyp
                                                      id         = msgid
                                                      number     = msgnr
                                                      message_v1 = msgv1
                                                      message_v2 = msgv2
                                                      message_v3 = msgv3
                                                      message_v4 = msgv4 ).

* ---------------------------------------------------------------------
  ENDMETHOD.

ENDCLASS.
