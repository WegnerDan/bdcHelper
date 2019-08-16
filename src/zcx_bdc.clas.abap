CLASS zcx_bdc DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES:
      if_t100_dyn_msg,
      if_t100_message.
    CONSTANTS:
      BEGIN OF syst_message,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '000',
        attr1 TYPE scx_attrname VALUE 'SYST-MSGV1',
        attr2 TYPE scx_attrname VALUE 'SYST-MSGV2',
        attr3 TYPE scx_attrname VALUE 'SYST-MSGV3',
        attr4 TYPE scx_attrname VALUE 'SYST-MSGV4',
      END OF syst_message,
      BEGIN OF transaction_error,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'TRANSACTION',
        attr2 TYPE scx_attrname VALUE 'SYST-SUBRC',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF transaction_error,
      BEGIN OF bdc_error,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF bdc_error,
      BEGIN OF queue_read_error,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'QUEUE_ID',
        attr2 TYPE scx_attrname VALUE 'TRANS_COUNT',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF queue_read_error.
    DATA:
      syst        TYPE sy,
      transaction TYPE sy-tcode,
      queue_id    TYPE apqi-qid,
      trans_count TYPE apq_tran.
    METHODS:
      constructor IMPORTING textid      LIKE if_t100_message=>t100key OPTIONAL
                            previous    LIKE previous OPTIONAL
                            syst        LIKE syst OPTIONAL
                            transaction LIKE transaction OPTIONAL
                            queue_id    LIKE queue_id OPTIONAL
                            trans_count LIKE trans_count OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_bdc IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
* ---------------------------------------------------------------------
    super->constructor( previous = previous ).

* ---------------------------------------------------------------------
    CLEAR me->textid.

* ---------------------------------------------------------------------
    me->syst = syst.
    me->transaction = transaction.
    me->queue_id = queue_id.
    me->trans_count = trans_count.

* ---------------------------------------------------------------------
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

* ---------------------------------------------------------------------
    IF if_t100_message~t100key = syst_message.
      if_t100_message~t100key-msgid = me->syst-msgid.
      if_t100_message~t100key-msgno = me->syst-msgno.
    ENDIF.

* ---------------------------------------------------------------------
  ENDMETHOD.

ENDCLASS.
