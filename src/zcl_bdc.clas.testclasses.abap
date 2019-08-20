CLASS lcl DEFINITION FOR TESTING.
  PRIVATE SECTION.
    METHODS:
      mi10 FOR TESTING.
ENDCLASS.

CLASS lcl IMPLEMENTATION.

  METHOD mi10.
* ---------------------------------------------------------------------
    DATA:
      lo_bdc TYPE REF TO zcl_bdc.

* ---------------------------------------------------------------------
    lo_bdc = NEW #( ).

* ---------------------------------------------------------------------
    lo_bdc->add_dynpro( iv_program = 'SAPMM07I' iv_dynpro  = '0700' ).
    lo_bdc->add_field( iv_name  = 'RM07I-ZLDAT'  iv_value = sy-datum ).
    lo_bdc->add_field( iv_name  = 'RM07I-BLDAT'  iv_value = sy-datum ).
    lo_bdc->add_field( iv_name  = 'IKPF-WERKS'   iv_value = '' ).
    lo_bdc->add_field( iv_name  = 'IKPF-LGORT'   iv_value = '' ).
    lo_bdc->add_field( iv_name  = 'IKPF-IBLTXT'  iv_value = 'Test' ).
    lo_bdc->add_okcode( zcl_bdc=>mc_okcode-button_enter ).

* ---------------------------------------------------------------------
    lo_bdc->add_dynpro( iv_program = 'SAPMM07I' iv_dynpro  = '0731' ).
    lo_bdc->add_field( iv_name  = 'ISEG-MATNR(01)'  iv_value = '' ).
    lo_bdc->add_field( iv_name  = 'ISEG-CHARG(01)'  iv_value = '' ).
    lo_bdc->add_field( iv_name  = 'ISEG-ERFMG(01)'  iv_value = '666' ).
    lo_bdc->add_okcode( '=BU' ).
    lo_bdc->add_dynpro( iv_program = 'SAPMM07I' iv_dynpro  = '0700' ).

* ---------------------------------------------------------------------
    lo_bdc->set_default_screen_size( ).
    lo_bdc->set_display_mode( zcl_bdc=>mc_dismode-dark ).

* ---------------------------------------------------------------------
    TRY.
        lo_bdc->execute( iv_tcode = 'MI10' ).
        DATA(lt_msg) = lo_bdc->get_messages( ).
      CATCH zcx_bdc INTO DATA(lx).
        MESSAGE lx TYPE 'E'.
    ENDTRY.

* ---------------------------------------------------------------------
  ENDMETHOD.

ENDCLASS.
