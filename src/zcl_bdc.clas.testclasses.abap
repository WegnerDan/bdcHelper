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
    lo_bdc->add_dynpro( program = 'SAPMM07I' dynpro = '0700' ).
    lo_bdc->add_field( name = 'RM07I-ZLDAT' value = sy-datum ).
    lo_bdc->add_field( name = 'RM07I-BLDAT' value = sy-datum ).
    lo_bdc->add_field( name = 'IKPF-WERKS' value = '' ).
    lo_bdc->add_field( name = 'IKPF-LGORT' value = '' ).
    lo_bdc->add_field( name = 'IKPF-IBLTXT' value = 'Test' ).
    lo_bdc->add_okcode( zcl_bdc=>c_okcode-button_enter ).

* ---------------------------------------------------------------------
    lo_bdc->add_dynpro( program = 'SAPMM07I' dynpro = '0731' ).
    lo_bdc->add_field( name = 'ISEG-MATNR(01)' value = '' ).
    lo_bdc->add_field( name = 'ISEG-CHARG(01)' value = '' ).
    lo_bdc->add_field( name = 'ISEG-ERFMG(01)' value = '666' ).
    lo_bdc->add_okcode( '=BU' ).
    lo_bdc->add_dynpro( program = 'SAPMM07I' dynpro = '0700' ).

* ---------------------------------------------------------------------
    lo_bdc->set_default_screen_size( ).
    lo_bdc->set_display_mode( zcl_bdc=>c_dismode-dark ).

* ---------------------------------------------------------------------
    TRY.
        lo_bdc->execute( tcode = 'MI10' ).
        DATA(lt_msg) = lo_bdc->get_messages( ).
      CATCH zcx_bdc INTO DATA(lx).
        MESSAGE lx TYPE 'E'.
    ENDTRY.

* ---------------------------------------------------------------------
  ENDMETHOD.

ENDCLASS.
