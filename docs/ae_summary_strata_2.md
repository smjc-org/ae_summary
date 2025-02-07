# %ae_summary_strata_2

## 简介

按系统器官分类、首选术语汇总不良事件。

## 语法

### 参数

#### 必选参数

- [indata](#indata)
- [outdata](#outdata)

#### 可选参数

- [aesoc](#aesoc)
- [aedecod](#aedecod)
- [aeseq](#aeseq)
- [usubjid](#usubjid)
- [arm](#arm)
- [arm_by](#arm_by)
- [sort_by](#sort_by)
- [at_least](#at_least)
- [at_least_text](#at_least_text)
- [unencoded_text]()
- [hypothesis](#hypothesis)
- [format_freq](#format_freq)
- [format_rate](#format_rate)
- [format_p](#format_p)
- [significance_marker](#significance_marker)

#### 调试参数

- [debug](#debug)

### 参数说明

#### indata

**Syntax** : _data-set-name_<(_data-set-option_)>

指定待分析的数据集，可使用数据集选项。

> [!IMPORTANT]
>
> `indata` 数据集必须包含所有安全性集的受试者和不良事件序号 [aeseq](#aeseq)，对于未发生不良事件的受试者，其不良事件序号 [aeseq](#aeseq) 应为空。

> [!TIP]
>
> 你可以参考下面的代码创建符合分析要求的数据集
>
> ```sas
> data analysis;
>     merge adam.adsl adam.adae;
>     by usubjid;
>     if saffl = "Y";
> run;
> ```

> [!IMPORTANT]
>
> 如需对不良事件中的某个子集进行分析，例如，汇总与试验医疗器械相关的不良事件，你应当先筛选 `aereldfl = "Y"`，再与 `adam.adsl` 合并：
>
> ```sas
> data analysis;
>   merge adam.adsl adam.adae(where = (aereldfl = "Y"));
>   by usubjid;
>   if saffl = "Y";
> run;
> ```
>
> 先与 `adam.adsl` 合并，再筛选 `aereldfl = "Y"` 的做法是错误的：
>
> ```sas
> data analysis;
>   merge adam.adsl adam.adae;
>   by usubjid;
>   if saffl = "Y" and aereldfl = "Y";
> run;
> ```

**Usage** :

```sas
indata = analysis
```

---

#### outdata

**Syntax** : _data-set-name_<(_data-set-option_)>

指定保存汇总结果的数据集，可使用数据集选项。

**Usage** :

```sas
outdata = t_7_3_6
```

---

#### aesoc

**Syntax** : _variable_

指定变量 `系统器官分类` 。

**Default** : `aesoc`

**Usage** :

```sas
aesoc = aebodsys
```

---

#### aedecod

**Syntax** : _variable_

指定变量 `首选术语` 。

**Default** : `aedecod`

**Usage** :

```sas
aedecod = aept
```

---

#### aeseq

**Syntax** : _variable_

指定变量 `不良事件序号` 。

> [!IMPORTANT]
>
> 对于发生了不良事件的观测，`aeseq` 不能是缺失值，但 [aesoc](#aesoc) 和 [aedecod](#aedecod) 可以是缺失值。

**Default** : `aeseq`

**Usage** :

```sas
aeseq = recrep
```

---

#### usubjid

**Syntax** : _variable_

指定变量 `受试者唯一编号` 。

**Default** : `usubjid`

**Usage** :

```sas
usubjid = usubjid
```

---

#### arm

**Syntax** : _variable_ | `#null`

指定变量 `试验组别` 。

**Default** : `#null`

默认情况下，将 [indata](#indata) 视为单组试验的数据集进行汇总。

**Usage** :

```sas
arm = arm
```

---

#### arm_by

**Syntax** :

- _variable_<(asc | desc \<ending>)>
- _format_<(asc | desc \<ending>)>
- `#null`

指定 [arm](#arm) 的排序方式。

> [!IMPORTANT]
>
> 1. 当指定一个变量 _`variable`_ 进行排序时，将按照 _`variable`_ 对 [arm](#arm) 各水平名称进行排序
> 2. 当指定一个输出格式 _`format`_ 进行排序时，将按照 _`format`_ 定义中的 _`value-or-range`_ 和 _`formatted-value`_ 的对应关系对 [arm](#arm) 各水平名称进行排序。_`format`_ 可以通过以下语句定义：
>
>    ```sas
>    proc format;
>        value armn
>            1 = "试验组"
>            2 = "对照组";
>    quit;
>    ```
>
> 3. `asc`, `ascending` 表示正向排序，`desc`, `descending` 表示逆向排序。

**Default** : `%nrstr(&arm)`

默认情况下，若 `arm = #null`，则将 [indata](#indata) 视为单组试验的数据集进行汇总，此时无需排序；若 `arm = ` _variable_，则根据 [arm](#arm) 自身的值排序。

**Usage** :

```sas
arm_by = arm(desc)
arm_by = armn.
```

---

#### sort_by

**Syntax** : <#G*number*>#<freq | time><(asc | desc \<ending>)>, ...

指定 [outdata](#outdata) 中观测的排序方式。

- #G*number* 表示按照第 _number_ 个组别排序，省略 #G*number* 表示按照合计结果排序，组别的 _number_ 值是由 [arm_by](#arm_by) 决定的。
- `freq` 表示按照频数排序，`time` 表示按照频次排序。
- `asc`, `ascending` 表示正向排序，`desc`, `descending` 表示逆向排序。

具体用法举例说明如下：

- `#FREQ(desc)` : 按照合计频数逆向排序。
- `#FREQ(desc) #TIME(asc)` : 按照合计频数逆向、合计频次正向排序。
- `#FREQ(desc) #G1#FREQ(desc)` : 按照合计频数逆向、第一个组别的频数逆向排序。
- `#G1#FREQ(desc) #G1#TIME(desc)` : 按照第一个组别的频数逆向、第一个组别的频次逆向排序。
- `#G1#FREQ(desc) #G2#TIME(desc)` : 按照第一个组别的频数逆向、第二个组别的频次逆向排序。
- `#G1#FREQ(desc) #G1#TIME(desc) #G2#FREQ(asc) #G2#TIME(asc)` : 按照第一个组别的频数逆向、第一个组别的频数正向、第二个组别的频数逆向、第二个组别的频次正向排序。
- `#G1#FREQ(desc) #G2#FREQ(asc) #G1#TIME(desc) #G2#TIME(asc)` : 按照第一个组别的频数逆向、第二个组别的频数正向、第一个组别的频次逆向、第二个组别的频次正向排序。

> [!IMPORTANT]
>
> - 单组试验不能指定 #G*number*
> - #G*number* 中的 _number_ 值不能超出由 [arm](#arm) 和 [arm_by](#arm_by) 限定的组别数量

**Default** : `#FREQ(desc) #TIME(desc)`

**Usage** :

```sas
sort_by = %str(#G1#FREQ(desc) #G1#TIME(desc) #G2#FREQ(desc) #G2#TIME(desc))
```

---

#### at_least

**Syntax** : `true` | `false`

指定是否在 [outdata](#outdata) 的第一行输出 `至少发生一次不良事件` 的汇总结果。

**Default** : `true`

**Usage** :

```sas
at_least = false
```

---

#### at_least_text

**Syntax** : _string_

指定当 `at_least = true` 时，[outdata](#outdata) 的第一行显示的描述性文本。

**Default** : `至少发生一次AE`

**Usage** :

```sas
at_least_text = %str(至少发生一次不良事件)
```

---

#### unencoded_text

**Syntax** : _string_

指定当出现未编码的不良事件（[aesoc](#aesoc) 或 [aedecod](#aedecod) 缺失）时，[outdata](#outdata) 显示的替代字符串。

**Default** : `未编码`

**Usage** :

```sas
unencoded_text = %str(未编码)
```

---

#### hypothesis

**Syntax** : `true` | `false`

指定是否进行假设检验。

> [!NOTE]
>
> - 当只有一个组别时，无法进行假设检验。
> - 当有两个或多个组别时，将进行卡方检验，若卡方检验不适用，则进行 Fisher 精确检验。

**Default** : `true`

**Usage** :

```sas
hypothesis = false
```

---

#### format_freq

**Syntax** : _format_

指定频数和频次的输出格式。

**Default** : `best12.`

**Usage** :

```sas
format_freq = 8.
```

---

#### format_rate

**Syntax** : _format_

指定率的输出格式。

**Default** : `percentn9.2`

**Usage** :

```sas
format_rate = 8.3
```

---

#### format_p

**Syntax** : _format_

指定 P 值的输出格式。

**Default** : `pvalue6.4`

**Usage** :

```sas
format_p = spvalue.
```

---

#### significance_marker

**Syntax** : _character_

指定假设检验 P < 0.05 时，在输出结果中额外添加的标记字符。例如，指定 `significance_marker = %str(*)` 时，若 P = 0.0023，将显示为 `0.0023*`。

**Default** : `*`

**Usage** :

```sas
significance_marker = %str(*)
```

---

#### debug

指定是否删除中间过程生成的数据集。

> [!NOTE]
>
> 这是一个用于开发者调试的参数，通常不需要关注。

**Syntax** : `true` | `false`

**Default** : `false`
