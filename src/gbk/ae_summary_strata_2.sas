/*
 * Macro Name:    ae_summary_strata_2
 * Macro Purpose: �����¼�����
 * Author:        wtwang
 * Version Date:  2025-02-06 0.1.0
*/

%macro ae_summary_strata_2(indata,
                           outdata,
                           aesoc         = aesoc,
                           aedecod       = aedecod,
                           aeseq         = aeseq,
                           usubjid       = usubjid,
                           arm           = #null,
                           armby         = #null,
                           sortby        = (#g1 = (#freq(desc), #time(desc))),
                           format_rate   = percentn9.2,
                           al_least      = true,
                           at_least_text = %str(���ٷ���һ��AE),
                           hypothesis    = false,
                           format_p      = pvalue6.4,
                           debug         = false) / parmbuff;
    /*  indata:        �����¼� ADaM ���ݼ�����
     *  outdata:       ���ܽ����������ݼ�����
     *  aesoc:         ����-ϵͳ���ٷ���
     *  aedecod:       ����-��ѡ����
     *  aeseq:         ����-�����¼����
     *  usubjid:       ����-������Ψһ���
     *  arm:           ����-�������#null ��ʾ����
     *  armby:         ����-���������������ݣ����ܵ�ȡֵ�У���ֵ�ͱ����������ʽ��#null��#null ��ʾ����
     *  sortby:        �����������������ݣ���ϸ�﷨�ο������ĵ�
     *  format_rate:   �ʵ������ʽ
     *  al_least:      �Ƿ��ڵ�һ��������ٷ���һ�β����¼���ͳ�ƽ��
     *  at_least_text: ���ٷ���һ�β����¼�ͳ�ƽ�����ı�����
     *  hypothesis:    �Ƿ���м������
     *  format_p:      p ֵ�������ʽ
     *  debug:         ����ģʽ
    */

    /*ͳһ������Сд*/
    %let indata      = %sysfunc(strip(%bquote(&indata)));
    %let outdata     = %sysfunc(strip(%bquote(&outdata)));
    %let aesoc       = %upcase(%sysfunc(strip(%bquote(&aesoc))));
    %let aedecod     = %upcase(%sysfunc(strip(%bquote(&aedecod))));
    %let aeseq       = %upcase(%sysfunc(strip(%bquote(&aeseq))));
    %let usubjid     = %upcase(%sysfunc(strip(%bquote(&usubjid))));
    %let arm         = %upcase(%sysfunc(strip(%bquote(&arm))));
    %let armby       = %upcase(%sysfunc(strip(%bquote(&armby))));
    %let sortby      = %upcase(%sysfunc(strip(%bquote(&sortby))));
    %let format_rate = %upcase(%sysfunc(strip(%bquote(&format_rate))));
    %let al_least    = %upcase(%sysfunc(strip(%bquote(&al_least))));
    %let hypothesis  = %upcase(%sysfunc(strip(%bquote(&hypothesis))));
    %let format_p    = %upcase(%sysfunc(strip(%bquote(&format_p))));
    %let debug       = %upcase(%sysfunc(strip(%bquote(&debug))));

    /*����Ԥ����*/
    /*arm*/
    %if %superq(arm) = #NULL %then %do;
        %let arm_n = 0;
    %end;

    /*armby*/
    %if %superq(arm) ^= #NULL %then %do;
        %if %superq(armby) = #NULL %then %do;
            %put ERROR: ���� ARM ��Ϊ #NULL������ָ�� ARMBY��;
            %goto exit;
        %end;
        %else %do;
            %let reg_armby_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)|(?:([A-Za-z_]+(?:\d+[A-Za-z_]+)?)\.))(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
            %if %sysfunc(prxmatch(&reg_armby_id, %superq(armby))) %then %do;
                %let armby_var       = %sysfunc(prxposn(&reg_armby_id, 1, %superq(armby)));
                %let armby_fmt       = %sysfunc(prxposn(&reg_armby_id, 2, %superq(armby)));
                %let armby_direction = %sysfunc(prxposn(&reg_armby_id, 3, %superq(armby)));

                /*���������*/
                %if %bquote(&armby_direction) = %bquote() %then %do;
                    %put NOTE: δָ�������������Ĭ���������У�;
                    %let armby_direction = ASCENDING;
                %end;
                %else %if %bquote(&armby_direction) = ASC %then %do;
                    %let armby_direction = ASCENDING;
                %end;
                %else %if %bquote(&armby_direction) = DESC %then %do;
                    %let armby_direction = DESCENDING;
                %end;

                /*ʹ�������ʽ*/
                %if %bquote(&armby_fmt) ^= %bquote() %then %do;
                    proc sql noprint;
                        select libname, memname, source into :armby_fmt_libname, :armby_fmt_memname, :armby_fmt_source from dictionary.formats where fmtname = "&armby_fmt";
                    quit;

                    proc format library = &armby_fmt_libname..&armby_fmt_memname cntlout = tmp_armby_fmt;
                        select &armby_fmt;
                    run;

                    proc sql noprint;
                        select distinct type into :armby_fmt_type from tmp_armby_fmt;
                        create table tmp_arm_sorted as select label, start, end from tmp_armby_fmt order by input(start, 8.) &armby_direction, input(end, 8.) &armby_direction;
                        select label into :arm_1- from tmp_arm_sorted;
                        %let arm_n = &sqlobs;
                    quit;
                %end;

                /*ʹ���������*/
                %if %bquote(&armby_var) ^= %bquote() %then %do;
                    proc sql noprint;
                        create table tmp_arm_sorted as select &arm, &armby_var from (select distinct &arm, &armby_var from %superq(indata)) order by &armby_var &armby_direction;
                        select &arm into :arm_1- from tmp_arm_sorted;
                    quit;
                    %let arm_n = &sqlobs;
                %end;
            %end;
            %else %do;
                %put ERROR: ���� armby = %bquote(&armby) ��ʽ����ȷ��;
                %goto exit;
            %end;
        %end;
    %end;


    /*���� indata*/
    data tmp_indata;
        set %superq(indata);
    run;

    /*����������Ӽ����ݼ�����������������*/
    proc sql noprint;
        select count(distinct usubjid) into :subj_n from tmp_indata;
        %put ERROR: &subj_n;
        %do i = 1 %to &arm_n;
            create table tmp_indata_arm_&i as select * from tmp_indata where &arm = %unquote(%str(%')%superq(arm_&i)%str(%'));
            select count(distinct usubjid) into :arm_&i._subj_n from tmp_indata_arm_&i;
            %put ERROR: &&arm_&i._subj_n;
        %end;
    quit;

    /*������������洢 aesoc, aedecod ��ˮƽ����*/
    proc sql noprint;
        select distinct &aesoc into :&aesoc._1- from tmp_indata;
        %let &aesoc._n = &sqlobs;
        %do i = 1 %to &&&aesoc._n;
            select distinct &aedecod into :&aesoc._&i._&aedecod._1- from tmp_indata where &aesoc = "&&aesoc_&i";
            %let &aesoc._&i._&aedecod._n = &sqlobs;
        %end;
    quit;

    /*���� aesoc, aedecod ֵ����󳤶�*/
    %let &aesoc._len_max   = 0;
    %let &aedecod._len_max = 0;
    %do i = 1 %to &&&aesoc._n;
        %let &aesoc._len_max = %sysfunc(max(%length(&&&aesoc._&i), &&&aesoc._len_max));
        %do j = 1 %to &&&aesoc._&i._&aedecod._n;
            %let &aedecod._len_max = %sysfunc(max(%length(&&&aesoc._&i._&aedecod._&j), &&&aedecod._len_max));
        %end;
    %end;

    /*��ȡ aesoc �� aedecod �ı�ǩ*/
    proc sql noprint;
        select label into :&aesoc._label   trimmed from dictionary.columns where libname = "WORK" and memname = "TMP_INDATA" and name = "&aesoc";
        select label into :&aedecod._label trimmed from dictionary.columns where libname = "WORK" and memname = "TMP_INDATA" and name = "&aedecod";
    quit;

    /*���������ݼ�*/
    data tmp_base;
        length AT_LEAST            $%length(%superq(at_least_text))
               AT_LEAST_FLAG       8
               &aesoc              $&&&aesoc._len_max
               &aesoc._FLAG        8
               &aedecod            $&&&aedecod._len_max
               &aedecod._FLAG      8
               %do i = 1 %to &arm_n;
                   &aesoc._G&i._FREQ   8
                   &aesoc._G&i._TIME   8
                   &aedecod._G&i._FREQ 8
                   &aedecod._G&i._TIME 8
               %end;
               &aesoc._ALL_FREQ    8
               &aesoc._ALL_TIME    8
               &aedecod._ALL_FREQ  8
               &aedecod._ALL_TIME  8
               ;
        label AT_LEAST       = %unquote(%str(%')%superq(at_least_text)%str(%'))
              AT_LEAST_FLAG  = %unquote(%str(%')%superq(at_least_text)��FLAG��%str(%'))
              &aesoc         = %unquote(%str(%')%superq(&aesoc._label)%str(%'))
              &aesoc._FLAG   = %unquote(%str(%')%superq(&aesoc._label)��FLAG��%str(%'))
              &aedecod       = %unquote(%str(%')%superq(&aedecod._label)%str(%'))
              &aedecod._FLAG = %unquote(%str(%')%superq(&aedecod._label)��FLAG��%str(%'))
              %do i = 1 %to &arm_n;
                  &aesoc._G&i._FREQ   = %unquote(%str(%')%superq(&aesoc._label)��%superq(arm_&i)-������%str(%'))
                  &aesoc._G&i._TIME   = %unquote(%str(%')%superq(&aesoc._label)��%superq(arm_&i)-���Σ�%str(%'))
                  &aedecod._G&i._FREQ = %unquote(%str(%')%superq(&aedecod._label)��%superq(arm_&i)-������%str(%'))
                  &aedecod._G&i._TIME = %unquote(%str(%')%superq(&aedecod._label)��%superq(arm_&i)-���Σ�%str(%'))
              %end;
              &aesoc._ALL_FREQ   = %unquote(%str(%')%superq(&aesoc._label)���ϼ�-������%str(%'))
              &aesoc._ALL_TIME   = %unquote(%str(%')%superq(&aesoc._label)���ϼ�-���Σ�%str(%'))
              &aedecod._ALL_FREQ = %unquote(%str(%')%superq(&aedecod._label)���ϼ�-������%str(%'))
              &aedecod._ALL_TIME = %unquote(%str(%')%superq(&aedecod._label)���ϼ�-���Σ�%str(%'))
              ;

        %do i = 1 %to &arm_n;
            &aesoc._G&i._FREQ = .;
            &aesoc._G&i._TIME = .;
            &aedecod._G&i._FREQ = .;
            &aedecod._G&i._TIME = .;
        %end;
        &aesoc._ALL_FREQ = .;
        &aesoc._ALL_TIME = .;
        &aedecod._ALL_FREQ = .;
        &aedecod._ALL_TIME = .;

        %do i = 1 %to &&&aesoc._n;
            AT_LEAST       = "";
            AT_LEAST_FLAG  = 0;
            &aesoc         = "&&&aesoc._&i";
            &aesoc._FLAG   = 1;
            &aedecod       = "";
            &aedecod._FLAG = .;
            output;
            %do j = 1 %to &&&aesoc._&i._&aedecod._n;
                AT_LEAST       = "";
                AT_LEAST_FLAG  = 0;
                &aesoc         = "&&&aesoc._&i";
                &aesoc._FLAG   = 0;
                &aedecod       = "&&&aesoc._&i._&aedecod._&j";
                &aedecod._FLAG = 1;
                output;
            %end;
        %end;
    run;

    /*ͳ�����ٷ���һ�β����¼�������������*/
    proc sql noprint;
        create table tmp_desc_at_least like tmp_base;
        insert into tmp_desc_at_least
            set AT_LEAST = "&at_least_text",
                AT_LEAST_FLAG = 1,
                %do i = 1 %to &arm_n;
                    &aesoc._G&i._FREQ = (select count(distinct &usubjid) from tmp_indata_arm_&i),
                    &aesoc._G&i._TIME = (select count(&usubjid)          from tmp_indata_arm_&i),
                    &aedecod._G&i._FREQ = &aesoc._G&i._FREQ,
                    &aedecod._G&i._TIME = &aesoc._G&i._TIME,
                %end;
                &aesoc._ALL_FREQ = (select count(distinct &usubjid) from tmp_indata),
                &aesoc._ALL_TIME = (select count(&usubjid)          from tmp_indata),
                &aedecod._ALL_FREQ = &aesoc._ALL_FREQ,
                &aedecod._ALL_TIME = &aesoc._ALL_TIME
                ;
    quit;

    /*ͳ�Ƹ���ͺϼƷ����Ĳ����¼�������������*/
    proc sql noprint;
        create table tmp_desc_arm as select * from tmp_base;
        update tmp_desc_arm
            set %do i = 1 %to &arm_n;
                    &aesoc._G&i._FREQ   = (select count(distinct &usubjid) from tmp_indata_arm_&i where tmp_indata_arm_&i..&aesoc = tmp_desc_arm.&aesoc),
                    &aesoc._G&i._TIME   = (select count(&usubjid)          from tmp_indata_arm_&i where tmp_indata_arm_&i..&aesoc = tmp_desc_arm.&aesoc),
                    &aedecod._G&i._FREQ = (select count(distinct &usubjid) from tmp_indata_arm_&i where tmp_indata_arm_&i..&aesoc = tmp_desc_arm.&aesoc and tmp_indata_arm_&i..&aedecod = tmp_desc_arm.&aedecod),
                    &aedecod._G&i._TIME = (select count(&usubjid)          from tmp_indata_arm_&i where tmp_indata_arm_&i..&aesoc = tmp_desc_arm.&aesoc and tmp_indata_arm_&i..&aedecod = tmp_desc_arm.&aedecod),
                %end;
                &aesoc._ALL_FREQ   = (select count(distinct &usubjid) from tmp_indata where tmp_indata.&aesoc = tmp_desc_arm.&aesoc),
                &aesoc._ALL_TIME   = (select count(&usubjid)          from tmp_indata where tmp_indata.&aesoc = tmp_desc_arm.&aesoc),
                &aedecod._ALL_FREQ = (select count(distinct &usubjid) from tmp_indata where tmp_indata.&aesoc = tmp_desc_arm.&aesoc and tmp_indata.&aedecod = tmp_desc_arm.&aedecod),
                &aedecod._ALL_TIME = (select count(&usubjid)          from tmp_indata where tmp_indata.&aesoc = tmp_desc_arm.&aesoc and tmp_indata.&aedecod = tmp_desc_arm.&aedecod)
                ;
    quit;

    /*�ϲ� tmp_desc_at_least �� tmp_desc_arm*/
    data tmp_desc;
        set tmp_desc_at_least tmp_desc_arm;
    run;

    /*���� P ֵ*/
    
    

    /*ɾ���м����ݼ�*/
    %if %bquote(&debug) = %upcase(false) %then %do;
        proc datasets library = work nowarn noprint;
            delete tmp_excel_attr
                   tmp_excel_data
                   tmp_excel_attr_trans
                   tmp_excel_data_processed
                   ;
        quit;
    %end;

    %exit:
    %put NOTE: ����� ae_summary_strata_2 �ѽ������У�;
%mend;


proc format;
    value armn
        1 = "������"
        2 = "������";
quit;

data analysis;
    merge adam.adsl adam.adae;
    by usubjid;
    if saffl = "Y";
run;

options symbolgen mlogic mprint;
%ae_summary_strata_2(indata = analysis, outdata = out_ae, arm = arm, armby = armn.);
options nosymbolgen nomlogic nomprint;

data a;
run;
