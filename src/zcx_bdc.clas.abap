CLASS zcx_bdc DEFINITION PUBLIC INHERITING FROM cx_dynamic_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES:
      if_t100_dyn_msg,
      if_t100_message.
    TYPES:
      BEGIN OF ty_parted_string,
        part1 TYPE c LENGTH 50,
        part2 TYPE c LENGTH 50,
        part3 TYPE c LENGTH 50,
        part4 TYPE c LENGTH 50,
      END OF ty_parted_string.
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
      END OF queue_read_error,
      BEGIN OF invalid_dismode,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'DISMODE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_dismode,
      BEGIN OF invalid_updmode,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE 'UPDMODE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_updmode,
      BEGIN OF invalid_cattmode,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE 'CATTMODE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_cattmode,
      BEGIN OF rfc_system_failure,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '000',
        attr1 TYPE scx_attrname VALUE 'RFC_SYS_FAIL_MSG_PARTED-PART1',
        attr2 TYPE scx_attrname VALUE 'RFC_SYS_FAIL_MSG_PARTED-PART2',
        attr3 TYPE scx_attrname VALUE 'RFC_SYS_FAIL_MSG_PARTED-PART3',
        attr4 TYPE scx_attrname VALUE 'RFC_SYS_FAIL_MSG_PARTED-PART4',
      END OF rfc_system_failure,
      BEGIN OF rfc_communication_failure,
        msgid TYPE symsgid VALUE 'Z_BDC',
        msgno TYPE symsgno VALUE '000',
        attr1 TYPE scx_attrname VALUE 'RFC_COM_FAIL_MSG_PARTED-PART1',
        attr2 TYPE scx_attrname VALUE 'RFC_COM_FAIL_MSG_PARTED-PART2',
        attr3 TYPE scx_attrname VALUE 'RFC_COM_FAIL_MSG_PARTED-PART3',
        attr4 TYPE scx_attrname VALUE 'RFC_COM_FAIL_MSG_PARTED-PART4',
      END OF rfc_communication_failure.
    DATA:
      syst                    TYPE sy READ-ONLY,
      transaction             TYPE sy-tcode READ-ONLY,
      queue_id                TYPE apqi-qid READ-ONLY,
      trans_count             TYPE apq_tran READ-ONLY,
      dismode                 TYPE ctu_params-dismode READ-ONLY,
      updmode                 TYPE ctu_params-updmode READ-ONLY,
      cattmode                TYPE ctu_params-cattmode READ-ONLY,
      rfc_sys_fail_msg        TYPE string READ-ONLY,
      rfc_com_fail_msg        TYPE string READ-ONLY,
      rfc_sys_fail_msg_parted TYPE ty_parted_string READ-ONLY,
      rfc_com_fail_msg_parted TYPE ty_parted_string READ-ONLY.
    METHODS:
      constructor IMPORTING textid           LIKE if_t100_message=>t100key OPTIONAL
                            previous         LIKE previous OPTIONAL
                            syst             LIKE syst OPTIONAL
                            transaction      LIKE transaction OPTIONAL
                            queue_id         LIKE queue_id OPTIONAL
                            trans_count      LIKE trans_count OPTIONAL
                            dismode          LIKE dismode OPTIONAL
                            updmode          LIKE updmode OPTIONAL
                            cattmode         LIKE cattmode OPTIONAL
                            rfc_sys_fail_msg TYPE string OPTIONAL
                            rfc_com_fail_msg TYPE string OPTIONAL.
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
    me->dismode = dismode.
    me->updmode = updmode.
    me->cattmode = cattmode.
    me->rfc_sys_fail_msg = rfc_sys_fail_msg.
    me->rfc_sys_fail_msg_parted = me->rfc_sys_fail_msg.
    me->rfc_com_fail_msg = rfc_com_fail_msg.
    me->rfc_com_fail_msg_parted = me->rfc_com_fail_msg.

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
