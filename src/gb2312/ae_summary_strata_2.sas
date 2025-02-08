/*
 * Macro Name:    ae_summary_strata_2
 * Macro Purpose: �����¼�����
 * Author:        wtwang
 * Version Date:  2025-02-07 0.1.0
*/

%macro ae_summary_strata_2(indata,
                           outdata,
                           aesoc                   = aesoc,
                           aedecod                 = aedecod,
                           aeseq                   = aeseq,
                           usubjid                 = usubjid,
                           arm                     = #null,
                           arm_by                  = %nrstr(&arm),
                           sort_by                 = %str(#FREQ(desc) #TIME(desc)),
                           at_least                = true,
                           at_least_text           = %str(���ٷ���һ��AE),
                           at_least_output_if_zero = false,
                           unencoded_text          = %str(δ����),
                           hypothesis              = false,
                           format_freq             = best12.,
                           format_rate             = percentn9.2,
                           format_p                = pvalue6.4,
                           significance_marker     = %str(*),
                           debug                   = false) / parmbuff;
    /*  indata:                 �����¼� ADaM ���ݼ�����
     *  outdata:                ������ܽ�������ݼ�����
     *  aesoc:                  ����-ϵͳ���ٷ���
     *  aedecod:                ����-��ѡ����
     *  aeseq:                  ����-�����¼����
     *  usubjid:                ����-������Ψһ���
     *  arm:                    ����-�������#null ��ʾ����
     *  arm_by:                 ����-������������ʽ�����ܵ�ȡֵ�У���ֵ�ͱ����������ʽ��#null��#null ��ʾ����
     *  sort_by:                ���ܽ�����ݼ��й۲������ʽ����ϸ�﷨�ο������ĵ�
     *  at_least:               �Ƿ��ڻ��ܽ�����ݼ��ĵ�һ��������ٷ���һ�β����¼���ͳ�ƽ��
     *  at_least_text:          at_least = true ʱ�����ܽ�����ݼ��ĵ�һ����ʾ���������ı�
     *  at_least_output_if_zero �����ٷ���һ�β����¼��ĺϼ�����Ϊ��ʱ���Ƿ���Ȼ�ڻ��ܽ�����ݼ������
     *  unencoded_text          �����¼�δ���룬�� aesoc, aedecod ȱʧʱ�����ܽ�����ݼ�����ʾ������ַ���
     *  hypothesis:             �Ƿ���м������
     *  format_freq:            ���������ε������ʽ
     *  format_rate:            �ʵ������ʽ
     *  format_p:               p ֵ�������ʽ
     *  significance_marker:    p ֵ < 0.05 �ı���ַ�
     *  debug:                  ����ģʽ
    */

    /*ͳһ������Сд*/
    %let indata                  = %sysfunc(strip(%superq(indata)));
    %let outdata                 = %sysfunc(strip(%superq(outdata)));
    %let aesoc                   = %upcase(%sysfunc(strip(%bquote(&aesoc))));
    %let aedecod                 = %upcase(%sysfunc(strip(%bquote(&aedecod))));
    %let aeseq                   = %upcase(%sysfunc(strip(%bquote(&aeseq))));
    %let usubjid                 = %upcase(%sysfunc(strip(%bquote(&usubjid))));
    %let arm                     = %upcase(%sysfunc(strip(%bquote(&arm))));
    %let arm_by                  = %upcase(%sysfunc(strip(%bquote(&arm_by))));
    %let sort_by                 = %upcase(%sysfunc(strip(%bquote(&sort_by))));
    %let at_least                = %upcase(%sysfunc(strip(%bquote(&at_least))));
    %let at_least_text           = %sysfunc(strip(%superq(at_least_text)));
    %let at_least_output_if_zero = %upcase(%sysfunc(strip(%bquote(&at_least_output_if_zero))));
    %let unencoded_text          = %sysfunc(strip(%superq(unencoded_text)));
    %let hypothesis              = %upcase(%sysfunc(strip(%bquote(&hypothesis))));
    %let format_freq             = %upcase(%sysfunc(strip(%bquote(&format_freq))));
    %let format_rate             = %upcase(%sysfunc(strip(%bquote(&format_rate))));
    %let format_p                = %upcase(%sysfunc(strip(%bquote(&format_p))));
    %let significance_marker     = %sysfunc(strip(%bquote(&significance_marker)));
    %let debug                   = %upcase(%sysfunc(strip(%bquote(&debug))));

    /*����Ԥ����*/
    /*arm*/
    %if %superq(arm) = #NULL %then %do;
        %let arm_n = 0;
    %end;

    /*arm_by*/
    %if %superq(arm) ^= #NULL %then %do;
        %if %superq(arm_by) = #NULL %then %do;
            %put ERROR: ���� ARM ��Ϊ #NULL������ָ�� arm_by��;
            %goto exit;
        %end;
        %else %do;
            %let reg_arm_by_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)|(?:([A-Za-z_]+(?:\d+[A-Za-z_]+)?)\.))(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
            %if %sysfunc(prxmatch(&reg_arm_by_id, %superq(arm_by))) %then %do;
                %let arm_by_var       = %sysfunc(prxposn(&reg_arm_by_id, 1, %superq(arm_by)));
                %let arm_by_fmt       = %sysfunc(prxposn(&reg_arm_by_id, 2, %superq(arm_by)));
                %let arm_by_direction = %sysfunc(prxposn(&reg_arm_by_id, 3, %superq(arm_by)));

                /*���������*/
                %if %bquote(&arm_by_direction) = %bquote() %then %do;
                    %put NOTE: δָ�������������Ĭ���������У�;
                    %let arm_by_direction = ASCENDING;
                %end;
                %else %if %bquote(&arm_by_direction) = ASC %then %do;
                    %let arm_by_direction = ASCENDING;
                %end;
                %else %if %bquote(&arm_by_direction) = DESC %then %do;
                    %let arm_by_direction = DESCENDING;
                %end;

                /*ʹ�ø�ʽ����*/
                %if %bquote(&arm_by_fmt) ^= %bquote() %then %do;
                    proc sql noprint;
                        select libname, memname, source into :arm_by_fmt_libname, :arm_by_fmt_memname, :arm_by_fmt_source from dictionary.formats where fmtname = "&arm_by_fmt";
                    quit;

                    proc format library = &arm_by_fmt_libname..&arm_by_fmt_memname cntlout = tmp_arm_by_fmt;
                        select &arm_by_fmt;
                    run;

                    proc sql noprint;
                        create table tmp_arm_sorted as
                            select
                                label,
                                (case when start = "LOW"  then -constant("BIG")
                                      when start = "HIGH" then  constant("BIG")
                                      else input(strip(start), 8.)
                                end)             as arm_by_fmt_start,
                                (case when end = "LOW"  then -constant("BIG")
                                      when end = "HIGH" then  constant("BIG")
                                      else input(strip(end), 8.)
                                end)             as arm_by_fmt_end
                            from tmp_arm_by_fmt
                            order by arm_by_fmt_start &arm_by_direction, arm_by_fmt_end &arm_by_direction;
                        select label into :arm_1- from tmp_arm_sorted;
                        %let arm_n = &sqlobs;
                    quit;
                %end;

                /*ʹ�ñ�������*/
                %if %bquote(&arm_by_var) ^= %bquote() %then %do;
                    proc sort data = %superq(indata) out = tmp_arm_sorted(keep = &arm) nodupkey;
                        by %if &arm_by_direction = DESCENDING %then %do; DESCENDING %end; &arm_by_var;
                    run;
                    proc sql noprint;
                        select &arm into :arm_1- from tmp_arm_sorted;
                    quit;
                    %let arm_n = &sqlobs;
                %end;
            %end;
            %else %do;
                %put ERROR: ���� arm_by = %superq(arm_by) ��ʽ����ȷ��;
                %goto exit;
            %end;
        %end;
    %end;

    /*sort_by*/
    %let reg_sort_by_unit_id = %sysfunc(prxparse(%bquote(/(?:#(G\d+))?#(FREQ|TIME)(?:\((ASC|DESC)(?:ENDING)?\))?/)));
    %let start = 1;
    %let stop = %length(&sort_by);
    %let position = 0;
    %let length = 0;
    %let sort_by_part_n = 0;
    %syscall prxnext(reg_sort_by_unit_id, start, stop, sort_by, position, length);
    %do %while (&position > 0);
        %let sort_by_part_n = %eval(&sort_by_part_n + 1);
        %let sort_by_part_&sort_by_part_n = %substr(&sort_by, &position, &length);
        %syscall prxnext(reg_sort_by_unit_id, start, stop, sort_by, position, length);
    %end;

    %if &sort_by_part_n = 0 %then %do;
        %put ERROR: ���� sort_by = %superq(sort_by) ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        %do i = 1 %to &sort_by_part_n;
            %if %sysfunc(prxmatch(&reg_sort_by_unit_id, &&sort_by_part_&i)) %then %do;
                %let sort_by_part_&i._arm       = %sysfunc(prxposn(&reg_sort_by_unit_id, 1, &&sort_by_part_&i)); /*�����ĸ��������*/
                %let sort_by_part_&i._stat      = %sysfunc(prxposn(&reg_sort_by_unit_id, 2, &&sort_by_part_&i)); /*����ʲôͳ��������*/
                %let sort_by_part_&i._direction = %sysfunc(prxposn(&reg_sort_by_unit_id, 3, &&sort_by_part_&i)); /*������*/

                %if &&sort_by_part_&i._arm = %bquote() %then %do;
                    %let sort_by_part_&i._arm = ALL;
                %end;
                %else %do;
                    %if %substr(&&sort_by_part_&i._arm, 2) > &arm_n %then %do;
                        %put ERROR: ������� &&sort_by_part_&i ָ���˲����ڵ����;
                        %goto exit;
                    %end;
                %end;

                %let sort_by_part_&i._direction = &&sort_by_part_&i._direction.ENDING;
            %end;
        %end;
    %end;

    /*hypothesis*/
    %if %superq(hypothesis) = TRUE %then %do;
        %if &arm_n < 2 %then %do;
            %put ERROR: ���������޷����м�����飡;
            %goto exit;
        %end;
    %end;


    /*���� indata*/
    data tmp_indata;
        set %superq(indata);

        if not missing(&aeseq) and missing(&aesoc)   then &aesoc   = %unquote(%str(%')%superq(unencoded_text)%str(%'));
        if not missing(&aeseq) and missing(&aedecod) then &aedecod = %unquote(%str(%')%superq(unencoded_text)%str(%'));
    run;

    /*����������Ӽ����ݼ�����������������*/
    proc sql noprint;
        select count(distinct usubjid) into :subj_n from tmp_indata;
        %do i = 1 %to &arm_n;
            create table tmp_indata_arm_&i as select * from tmp_indata where &arm = %unquote(%str(%')%superq(arm_&i)%str(%'));
            select count(distinct usubjid) into :arm_&i._subj_n from tmp_indata_arm_&i;
        %end;
    quit;

    /*������������洢 aesoc, aedecod ��ˮƽ����*/
    proc sql noprint;
        select distinct &aesoc into :&aesoc._1- from tmp_indata where not missing(&aeseq);
        %let &aesoc._n = &sqlobs;
        %do i = 1 %to &&&aesoc._n;
            select distinct &aedecod into :&aesoc._&i._&aedecod._1- from tmp_indata where not missing(&aeseq) and &aesoc = "&&&aesoc._&i";
            %let &aesoc._&i._&aedecod._n = &sqlobs;
        %end;
    quit;

    /*���� aesoc, aedecod ֵ����󳤶�*/
    %let &aesoc._len_max   = 1;
    %let &aedecod._len_max = 1;
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
    proc sql noprint;
        create table tmp_base
            (
                AT_LEAST                char(%length(%superq(at_least_text))) label = %unquote(%str(%')%superq(at_least_text)%str(%')),
                AT_LEAST_FLAG           num(8)                                label = %unquote(%str(%')%superq(at_least_text)��FLAG��%str(%')),
                &aesoc                  char(&&&aesoc._len_max)               label = %unquote(%str(%')%superq(&aesoc._label)%str(%')),
                &aesoc._FLAG            num(8)                                label = %unquote(%str(%')%superq(&aesoc._label)��FLAG��%str(%')),
                &aedecod                char(&&&aedecod._len_max)             label = %unquote(%str(%')%superq(&aedecod._label)%str(%')),
                &aedecod._FLAG          num(8)                                label = %unquote(%str(%')%superq(&aedecod._label)��FLAG��%str(%')),
                %do i = 1 %to &arm_n;
                    &aesoc._G&i._FREQ   num(8)                                label = %unquote(%str(%')%superq(&aesoc._label)��%superq(arm_&i)-������%str(%')),
                    &aesoc._G&i._TIME   num(8)                                label = %unquote(%str(%')%superq(&aesoc._label)��%superq(arm_&i)-���Σ�%str(%')),
                    &aedecod._G&i._FREQ num(8)                                label = %unquote(%str(%')%superq(&aedecod._label)��%superq(arm_&i)-������%str(%')),
                    &aedecod._G&i._TIME num(8)                                label = %unquote(%str(%')%superq(&aedecod._label)��%superq(arm_&i)-���Σ�%str(%')),
                    G&i._FREQ           num(8)                                label = %unquote(%str(%')%superq(arm_&i)-����%str(%')),
                    G&i._TIME           num(8)                                label = %unquote(%str(%')%superq(arm_&i)-����%str(%')),
                    G&i._RATE           num(8)                                label = %unquote(%str(%')%superq(arm_&i)-��%str(%')),
                %end;
                &aesoc._ALL_FREQ        num(8)                                label = %unquote(%str(%')%superq(&aesoc._label)���ϼ�-������%str(%')),
                &aesoc._ALL_TIME        num(8)                                label = %unquote(%str(%')%superq(&aesoc._label)���ϼ�-���Σ�%str(%')),
                &aedecod._ALL_FREQ      num(8)                                label = %unquote(%str(%')%superq(&aedecod._label)���ϼ�-������%str(%')),
                &aedecod._ALL_TIME      num(8)                                label = %unquote(%str(%')%superq(&aedecod._label)���ϼ�-���Σ�%str(%')),
                ALL_FREQ                num(8)                                label = %unquote(%str(%')�ϼ�-����%str(%')),
                ALL_TIME                num(8)                                label = %unquote(%str(%')�ϼ�-����%str(%')),
                ALL_RATE                num(8)                                label = %unquote(%str(%')�ϼ�-��%str(%'))
            );
        
        %do i = 1 %to &&&aesoc._n;
            insert into tmp_base
                set AT_LEAST       = "",
                    AT_LEAST_FLAG  = 0,
                    &aesoc         = "&&&aesoc._&i",
                    &aesoc._FLAG   = 1,
                    &aedecod       = "",
                    &aedecod._FLAG = .
                    ;
            %do j = 1 %to &&&aesoc._&i._&aedecod._n;
                insert into tmp_base
                    set AT_LEAST       = "",
                        AT_LEAST_FLAG  = 0,
                        &aesoc         = "&&&aesoc._&i",
                        &aesoc._FLAG   = 0,
                        &aedecod       = "&&&aesoc._&i._&aedecod._&j",
                        &aedecod._FLAG = 1
                        ;
            %end;
        %end;
    quit;

    /*ͳ�����ٷ���һ�β����¼�������������*/
    %if %superq(at_least) = TRUE %then %do;
        proc sql noprint;
            create table tmp_desc_at_least like tmp_base;
            insert into tmp_desc_at_least
                set AT_LEAST = %unquote(%str(%')%superq(at_least_text)%str(%')),
                    AT_LEAST_FLAG = 1,
                    %do i = 1 %to &arm_n;
                        &aesoc._G&i._FREQ   = (select count(distinct &usubjid) from tmp_indata_arm_&i where not missing(&aeseq)),
                        &aesoc._G&i._TIME   = (select count(&usubjid)          from tmp_indata_arm_&i where not missing(&aeseq)),
                    %end;
                    &aesoc._ALL_FREQ   = (select count(distinct &usubjid) from tmp_indata where not missing(&aeseq)),
                    &aesoc._ALL_TIME   = (select count(&usubjid)          from tmp_indata where not missing(&aeseq))
                    ;
            update tmp_desc_at_least
                set %do i = 1 %to &arm_n;
                        &aedecod._G&i._FREQ = &aesoc._G&i._FREQ,
                        &aedecod._G&i._TIME = &aesoc._G&i._TIME,
                        G&i._FREQ           = &aesoc._G&i._FREQ,
                        G&i._TIME           = &aesoc._G&i._TIME,
                    %end;
                    &aedecod._ALL_FREQ = &aesoc._ALL_FREQ,
                    &aedecod._ALL_TIME = &aesoc._ALL_TIME,
                    ALL_FREQ           = &aesoc._ALL_FREQ,
                    ALL_TIME           = &aesoc._ALL_TIME
                    ;
            update tmp_desc_at_least
                set %do i = 1 %to &arm_n;
                        G&i._RATE = G&i._FREQ / &&arm_&i._subj_n,
                    %end;
                    ALL_RATE = ALL_FREQ / &subj_n
                    ;
            %if %superq(at_least_output_if_zero) = FALSE %then %do;
                delete from tmp_desc_at_least where ALL_FREQ = 0;
            %end;
        quit;
    %end;

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
        update tmp_desc_arm
            set %do i = 1 %to &arm_n;
                    G&i._FREQ           = ifn(&aesoc._FLAG = 1, &aesoc._G&i._FREQ, ifn(&aedecod._FLAG = 1, &aedecod._G&i._FREQ, .)),
                    G&i._TIME           = ifn(&aesoc._FLAG = 1, &aesoc._G&i._TIME, ifn(&aedecod._FLAG = 1, &aedecod._G&i._TIME, .)),
                %end;
                ALL_FREQ           = ifn(&aesoc._FLAG = 1, &aesoc._ALL_FREQ, ifn(&aedecod._FLAG = 1, &aedecod._ALL_FREQ, .)),
                ALL_TIME           = ifn(&aesoc._FLAG = 1, &aesoc._ALL_TIME, ifn(&aedecod._FLAG = 1, &aedecod._ALL_TIME, .))
                ;
        update tmp_desc_arm
            set %do i = 1 %to &arm_n;
                    G&i._RATE = G&i._FREQ / &&arm_&i._subj_n,
                %end;
                ALL_RATE = ALL_FREQ / &subj_n
                ;
    quit;

    /*�ϲ� <tmp_desc_at_least> �� tmp_desc_arm*/
    data tmp_desc;
        set %if %superq(at_least) = TRUE %then %do;
                tmp_desc_at_least
            %end;
                tmp_desc_arm;
    run;

    /*���� P ֵ*/
    proc sql noprint;
        select * from tmp_desc;
    quit;
    %if &sqlobs > 0 and %superq(hypothesis) = TRUE %then %do;
        /*ת�ã���������������¼�����������ͬһ����*/
        proc transpose data = tmp_desc out = tmp_contigency_subset_pos label = ARM;
            var %do i = 1 %to &arm_n; G&i._FREQ %end;;
            by AT_LEAST AT_LEAST_FLAG &aesoc &aesoc._FLAG &aedecod &aedecod._FLAG notsorted;
        run;

        /*��������δ���������¼�������*/
        data tmp_contigency;
            set tmp_contigency_subset_pos(rename = (COL1 = FREQ));
            label ARM = "ARM";
            ARM = kscan(ARM, 1, "-");
            by AT_LEAST AT_LEAST_FLAG &aesoc &aesoc._FLAG &aedecod &aedecod._FLAG notsorted;

            length STATUS $12;
            STATUS = "EXPOSED";
            output;
            %do i = 1 %to &arm_n;
                if _NAME_ = "G&i._FREQ" then FREQ = &&arm_&i._subj_n - FREQ;
            %end;
            STATUS = "NOT EXPOSED";
            output;
        run;

        /*����Ƿ����ٴ���ĳһ�л�ĳһ�е�Ƶ��֮��Ϊ��*/
        ods html close;
        ods output CrossTabFreqs = tmp_cross_tab_freqs(where = (_TYPE_ in ("01", "10")));
        proc freq data = tmp_contigency;
            tables ARM * STATUS;
            weight FREQ /zeros;
            by AT_LEAST AT_LEAST_FLAG &aesoc &aesoc._FLAG &aedecod &aedecod._FLAG notsorted;
        run;
        ods html;

        proc sql noprint;
            select * from tmp_cross_tab_freqs where Frequency = 0;
        quit;

        /*������и���Ƶ��֮�;������㣬����Խ��м������*/
        %if &sqlobs = 0 %then %do;
            ods html close;
            ods output ChiSq    = tmp_chisq(where = (Statistic = "����"))
                   FishersExact = tmp_fishers_exact(where = (Name1 = "XP2_FISH"));
            proc freq data = tmp_contigency;
                tables ARM * STATUS /chisq(warn = output);
                exact fisher;
                weight FREQ /zeros;
                by AT_LEAST AT_LEAST_FLAG &aesoc &aesoc._FLAG &aedecod &aedecod._FLAG notsorted;
            run;
            ods html;

            %let hypothesis_done = TRUE;

            data tmp_summary;
                merge tmp_desc
                      tmp_chisq(keep = Value Prob Warning rename = (Value = CHISQ Prob = CHISQ_PVALUE Warning = CHISQ_WARNING))
                      tmp_fishers_exact(keep = nValue1 rename = (nValue1 = FISHER_PVALUE));
                PVALUE = ifn(CHISQ_WARNING = 1, FISHER_PVALUE, CHISQ_PVALUE);

                label CHISQ         = "����ͳ����"
                      CHISQ_PVALUE  = "�������� P ֵ"
                      CHISQ_WARNING = "��������"
                      FISHER_PVALUE = "��ȷ���� P ֵ"
                      PVALUE        = "P ֵ"
                      ;
            run;
        %end;
        /*���������ʾ��Ϣ*/
        %else %do;
            %put NOTE: ����ĳһ�л�ĳһ�е�Ƶ��֮��Ϊ�㣬��������޷����У�;
            %let hypothesis_done = FALSE;

            data tmp_summary;
                set tmp_desc;
            run;
        %end;
    %end;
    %else %do;
        %let hypothesis_done = FALSE;

        data tmp_summary;
            set tmp_desc;
        run;
    %end;

    /*Ӧ�� format*/
    proc sql noprint;
        create table tmp_summary_formated as
            select
                *,
                (case when AT_LEAST_FLAG  = 1 then AT_LEAST
                      when &aesoc._FLAG   = 1 then &aesoc
                      when &aedecod._FLAG = 1 then "    " || &aedecod
                      else ""
                end)                                                                                       as ITEM          label = "��Ŀ",
                %do i = 1 %to &arm_n;
                    kstrip(put(G&i._RATE, &format_rate))                                                   as G&i._RATE_FMT label = %unquote(%str(%')%superq(arm_&i)-�ʣ�C��%str(%')),
                    kstrip(put(G&i._FREQ, &format_freq)) || "(" || kstrip(calculated G&i._RATE_FMT) || ")" as G&i._VALUE1   label = %unquote(%str(%')%superq(arm_&i)-�������ʣ�%str(%')),
                    kstrip(put(G&i._TIME, &format_freq))                                                   as G&i._VALUE2   label = %unquote(%str(%')%superq(arm_&i)-����%str(%')),
                %end;
                kstrip(put(ALL_RATE, &format_rate))                                                        as ALL_RATE_FMT  label = %unquote(%str(%')�ϼ�-�ʣ�C��%str(%')),
                kstrip(put(ALL_FREQ, &format_freq)) || "(" || kstrip(calculated ALL_RATE_FMT) || ")"       as ALL_VALUE1    label = %unquote(%str(%')�ϼ�-�������ʣ�%str(%')),
                kstrip(put(ALL_TIME, &format_freq))                                                        as ALL_VALUE2    label = %unquote(%str(%')�ϼ�-����%str(%'))
                %if &hypothesis_done = TRUE %then %do;
                    %bquote(,)
                    kstrip(put(PVALUE, &format_p)) || ifc(PVALUE < 0.05, "&significance_marker", "")       as PVALUE_FMT    label = "Pֵ"
                %end;
            from tmp_summary;
    quit;

    /*����*/
    proc sql noprint sortseq = linguistic;
        create table tmp_summary_formated_sorted as
            select * from tmp_summary_formated
            order by AT_LEAST_FLAG descending,
                     %do i = 1 %to &sort_by_part_n;
                         &aesoc._&&sort_by_part_&i._arm._&&sort_by_part_&i._stat &&sort_by_part_&i._direction,
                     %end;
                     &aesoc,
                     &aesoc._FLAG descending,
                     %do i = 1 %to &sort_by_part_n;
                         &aedecod._&&sort_by_part_&i._arm._&&sort_by_part_&i._stat &&sort_by_part_&i._direction,
                     %end;
                     &aedecod
                     ;
    quit;

    /*������ݼ�*/
    data &outdata;
        set tmp_summary_formated_sorted;
        keep ITEM
             %do i = 1 %to &arm_n;
                 G&i._VALUE1
                 G&i._VALUE2
             %end;
             ALL_VALUE1
             ALL_VALUE2
             %if &hypothesis_done = TRUE %then %do;
                PVALUE_FMT
             %end;
             ;
    run;

    /*ɾ���м����ݼ�*/
    %if %bquote(&debug) = %upcase(false) %then %do;
        proc datasets library = work nowarn noprint;
            delete tmp_arm_by_fmt
                   tmp_arm_sorted
                   tmp_indata
                   %do i = 1 %to &arm_n;
                       tmp_indata_arm_&i
                   %end;
                   tmp_base
                   tmp_desc_at_least
                   tmp_desc_arm
                   tmp_desc
                   tmp_contigency_subset_pos
                   tmp_contigency
                   tmp_chisq
                   tmp_fishers_exact
                   tmp_summary
                   tmp_summary_formated
                   tmp_summary_formated_sorted
                   ;
        quit;
    %end;

    %exit:
    %put NOTE: ����� ae_summary_strata_2 �ѽ������У�;
%mend;
