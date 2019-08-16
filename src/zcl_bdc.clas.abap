CLASS zcl_bdc DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      mty_t_bdcdata TYPE STANDARD TABLE OF bdcdata WITH DEFAULT KEY.
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
      END OF mc_updmode.
    DATA:
      ms_options TYPE ctu_params.
    METHODS:
      constructor IMPORTING it_bdcdata TYPE mty_t_bdcdata OPTIONAL,
      load_queue IMPORTING iv_qid   TYPE apqi-qid
                           iv_trans TYPE apq_tran
                 RAISING   zcx_bdc,
      add_dynpro IMPORTING iv_program TYPE bdcdata-program
                           iv_dynpro  TYPE bdcdata-dynpro,
      add_field IMPORTING iv_name      TYPE bdcdata-fnam
                          iv_value     TYPE any
                          iv_use_write TYPE abap_bool DEFAULT abap_true,
      execute IMPORTING iv_tcode      TYPE sy-tcode
              RETURNING VALUE(rt_msg) TYPE tab_bdcmsgcoll
              RAISING   zcx_bdc,
      get_bdcdata RETURNING VALUE(rt_bdcdata) TYPE mty_t_bdcdata.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      mt_bdcdata TYPE mty_t_bdcdata.
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
        CALL TRANSACTION   iv_tcode
             USING         mt_bdcdata
             OPTIONS FROM  ms_options
             MESSAGES INTO rt_msg.
        IF  sy-subrc > 0
        AND sy-subrc < 1001.
          RAISE EXCEPTION TYPE zcx_bdc
            EXPORTING
              textid      = zcx_bdc=>transaction_error
              syst        = sy
              transaction = iv_tcode.
        ELSEIF sy-subrc > 1000.
          RAISE EXCEPTION TYPE zcx_bdc
            EXPORTING
              textid = zcx_bdc=>bdc_error.
        ENDIF.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_bdc
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
        queue_id  = iv_qid
        trans     = iv_trans
      TABLES
        dynprotab = mt_bdcdata
      EXCEPTIONS
        OTHERS    = 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_bdc.
    ENDIF.

* ---------------------------------------------------------------------
  ENDMETHOD.


  METHOD get_bdcdata.
* ---------------------------------------------------------------------
    rt_bdcdata = mt_bdcdata.

* ---------------------------------------------------------------------
  ENDMETHOD.

ENDCLASS.
