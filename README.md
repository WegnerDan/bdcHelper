# bdc_helper

Helper class for Batch Data Communication (batch input)

## Usage Example
```abap
* ---------------------------------------------------------------------
    DATA:
      bdc TYPE REF TO zcl_bdc.

* ---------------------------------------------------------------------
    bdc = NEW #( ).

* ---------------------------------------------------------------------
    bdc->add_dynpro( program = 'SAPMM07I' dynpro  = '0700' ).
    bdc->add_field( name  = 'RM07I-ZLDAT'  value = sy-datum ).
    bdc->add_field( name  = 'RM07I-BLDAT'  value = sy-datum ).
    bdc->add_field( name  = 'IKPF-WERKS'   value = 'Werk' ).
    bdc->add_field( name  = 'IKPF-LGORT'   value = 'Lagerort' ).
    bdc->add_field( name  = 'IKPF-IBLTXT'  value = 'Test' ).
    bdc->add_okcode( zcl_bdc=>mc_okcode-button_enter ).

* ---------------------------------------------------------------------
    bdc->add_dynpro( program = 'SAPMM07I' dynpro  = '0731' ).
    bdc->add_field( name  = 'ISEG-MATNR(01)'  value = 'Material' ).
    bdc->add_field( name  = 'ISEG-ERFMG(01)'  value = '666' ).
    bdc->add_okcode( '=BU' ).
    bdc->add_dynpro( program = 'SAPMM07I' dynpro  = '0700' ).

* ---------------------------------------------------------------------
    bdc->set_default_screen_size( ).
    bdc->set_display_mode( zcl_bdc=>mc_dismode-dark ).

* ---------------------------------------------------------------------
    TRY.
        bdc->execute( tcode = 'MI10' ).
        DATA(messages) = bdc->get_messages( ).
      CATCH zcx_bdc INTO DATA(bdc_error).
        MESSAGE bdc_error TYPE 'E'.
    ENDTRY.

* ---------------------------------------------------------------------
```
