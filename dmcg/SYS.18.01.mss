@make(ptreport)
@device(dover)
@font(timesroman10)
@Define(Ins,Break,Continue,Above 1,Below 1,Fill,LeftMargin +1.3 inches,
	Spaces Compact,Indent 0,Spacing 1)

@string(ptgdno="SYS.18.01")
@begin(titlepage)
@document(A Machine-Independent MDL
Design Document)
@author(Marc S. Blank and Chris Reeve)
@date(@value(date))
@end(titlepage)

@pageheading<Left="PTDD",Center="@value<page>",Right="SYS.18.01">

@chapter<Global Design>
@section<The MIM Virtual Machine>
There are a number of possible approaches to re-implementing MDL on
various processors; the one chosen for this design is to create a
virtual machine running a language called MIM (Machine-Independent MDL).
The approach is analogous to that taken with Pascal in that MIM is either an
interpreted or compiled language, and interpreters or compilers must be
written for each target
machine. MIM code will be generated from MDL code by a process called
MIMC (the MIM compiler, pronounced mimsy), which will be written in MDL.

At the point that an Apollo-MIM (for example) and MIMC are operational, a
MDL interpreter written in MDL (called MUM) can be compiled into MIM.
MIMC, which will also be written in MDL, can also be compiled into MIM,
thereby providing both an MDL interpreter and compiler running on the
Apollo.  It is also proposed that an order-code compiler for the various
target machines be written, to 'open-code' MIM into target machine
languages, with an increase in speed traded off for an increase in code
length.  While MIMOC (MIM Order Compiler) may well become a necessity
for runtime systems, it need not become operational for writing,
running, and debugging MDL code.

A major difference between Pascal P-CODEs and MIM M-CODES is that the
latter are in themselves a high-level language, with machine
instructions which handle such things as RESTing structures, creating
structures, etc.  Therefore, very little information of a
machine-dependent nature is stored in MIM machine code.  By keeping MIM
relatively independent of target machine design, better target machine
code can eventually be produced by the MIMOC process.

@section<MIM Design Goals>
MIM (Machine-Independent MDL) is designed to enable the MDL language to
be rapidly implemented on a variety of machines.  Although the language
specification is 'machine-independent', it is nonetheless designed with
8/16/32/36 bit processors in mind.

In the design of MIM, the goal has been to extract those features of
MDL which are 'primitive' and to make those 'primitives' machine instructions.
Thus, the MIM machine must understand the concept of an MDL object, MDL
structured primtypes, etc.  However, it is clear that most of the MDL
SUBR/FSUBR's are composites of 'primitives' and that in fact few of
the MDL SUBR/FSUBR's need be implemented as machine instructions.
For example, MEMQ need not exist given NTH, REST, and ==?.  More difficult
questions have involved such issues as whether READ can be written
efficiently in MDL given only READSTRING, and how much of the ATOM/OBLIST
system can be written in MDL.  

@chapter<MIM Machine Structure>
@tabclear<>
@tabset<1.3 inches,2.5 inches>
@section<MIM Instruction Format>
Each MIM instructions takes a number of arguments and a destination designator
for the result if any.

The arguments to a MIM instruction can be either local variable names or
quoted MDL objects.  The result of a MIM instruction can either be a local
variable or the atom STACK which directs the instruction to leave the
result on the stack.

In describing the instruction set the following convention will
be used in denoting operands:
@begin<format>

	@i<operand-type:MDL-type-or-primtype>
@end<format>
where @i<operand-type> is one of local or any (meaning either a local or
constant) and
@i<MDL-type-or-primtype> indicates the legal value(s) for that operand.

@section<MIM Predicates>

Some MIM instructions are predicates.  These all have mnemonics which
end in a question mark (e.g. EQUAL?).  These instructions are all
followed by a + or - to indicate whether the branch should be taken
if the predicate is true or false.  After the + or -, the branch label
occurs.

@section<MIM Internal Variables>
MIM has a few internal variables, which may be read and set.  These variables
should not be confused with global or local variables in MDL.  They are more
like MIM state variables.

@begin<enumerate>
MINF - a UVECTOR of information about the machine on which MIM is running

PAGETB - a UVECTOR of information about the address space available to MIM 

BIND - the most recent binding on the STACK

FRAME - the current FRAME

ARGS - the number of arguments to the current FRAME

OBLIST- the global atom-table

ICALL - the @b(MSUBR) to CALL when an interrupt occurs

ECALL - the @b(MSUBR) to CALL when an error in order-code occurs

NCALL - the @b(MSUBR) to CALL when a non-globally-assigned @b(ATOM) or
an @b(ATOM) whose global value is not an @b(MSUBR) is CALLed 
@end<enumerate>

The last three internal variables are intended to be set once during
initialization of the MDL interpreter.  Extreme caution should be used
when setting the BIND, ARGS, FRAME, and OBLIST variables, as these
are used internally for @b(MSUBR) CALLing, etc.  

@section<MIM Objects>
A MIM object is a 64-bit or 72-bit structure which is roughly equivalent to
the PDP-10 MDL type/value pair.  A MIM object contains the following
items:
@begin<itemize>
Type Word - 16 or 18 bits specifying the type and primtype of the object.  See
@i<TYPE-WORD Format>.

Length Word - 16 or 18 bits. See @i<LENGTH-WORD Description>

Value - 32 or 36 bits, a pointer for structures or a value for non-structures.
@end<itemize>

@section<MIM Subroutines>

The unit of executable MIM code is the @b(MSUBR) (@b(M)dl
@b(SUBR)outine).  This has a format as diagrammed in @i<MSUBR Format>.
Briefly, an @b(MSUBR) is a primtype @b(VECTOR) which contains a pointer to
an @b(IMSUBR) which is a primtype @b(VECTOR) and contains a pointer to
runnable MIM instructions (a primtype @b(UVECTOR) of type @t(MCODE)), as
well as other MDL objects used by the @b(MSUBR).  By convention, the second
element of the MSUBR is its name (an @b(ATOM)), the third is the
type declaration for the MSUBR (a @b(LIST)) and the fourth is the offset
into the MCODE where the code for this MSUBR starts. When an MSUBR wants to
reference an MIM object, it refers to an offset in the IMSUBR.  The CALL
instruction makes the MIM program counter point to the appropriate element of
the @b(MCODE) for the called @b(MSUBR).

@section<MIM Stack>

MIM has a stack (referred to as the STACK) which is used for MSUBR
calling, bindings, local variables, temporaries, etc. All items on the
STACK are either legal MIM objects (i.e. 64-bit structures) or
structures placed there by MIM instructions (e.g. FRAME, BIND).

@chapter<MIM Instruction Overview>

@section<Stack & Variable Operations>

MIM has instructions for placing objects on the STACK (PUSH) and for
removing objects from the top of the STACK (POP).  In addition, the
instruction ADJ adjusts the STACK pointer either forward or backward by
a given number of MIM objects.

MIM local variables (located on the STACK) can be set with the various
SET instructions to either the value of another local variable, a slot
in the @b(IMSUBR) or a constant.

@section<MSUBR Calling>

In order to transfer control from one @b(MSUBR) to another, a STACK @b(FRAME)
must be created.  This is done using the FRAME instruction.  Such a
@b(FRAME) will contain enough inforiadio, to$anlow DrMCUBTh Bet5xls,mulpip|d`6etur.1, !nd`MDL)style AGAIN." NLe the @v FAOE	 is btHnT, theargumenlc un dhe @b(MFBR)(HiF@aFy	 avE USId$ Knto thE QTACJ. `TIenL
tam AL ivsTruwtyn is!ayEcetem. 
Hgse kc an`a{`)mT(mf`tie0usg (iF`II awSmlbmq Da~gqege novatinli on 5(DcAM instbugtinn:@bggin<vewBc4km>
        <FRAMA>    ('`   `( 0     $`      ; cre`tm ` ctack Dramm
`     ` <PSH   NOO> "               0  ! (push!th hocil v`riablM DO   @`  H<PQ	BpQQl gF'o|OOOOWOMKOGOM@__O *(^p0OOGOOOKA_O_F@OOOOoOOOI_O_OoaONI=GP9:ysezEBBF  cgw{x'/sg'ea_rSfdd	v42@`> )  &  (6   5  4  3  8  ({   z  )  0D  (C   B  	  	      x  :  (t   s  r%A   (?  fAG   $D[@   -5   65d  u\C`X  '.LG  \CO4  =\Dw  u(X  |
\|Pd  U4zc	   m:  Oi<  l
M [  u
M `  R
8	^  \KyP  M
M `  
~s ?  &
e,  <
+  MQ7P  _D^  D^  +D^  9
`;  Y]c"  \D%:  $>/g0  .KyP  4T0  C(I  Q
|T  m"QO   8 $                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          rnal representation of the various structure classes. 

@section<MIM Support for ATOMs and Bindings>

MIM supports the concepts of @b(ATOM)s and bindings.  This is necessary
in that a completely external simulation of atomic bindings would be
unreasonably expensive without some knowledge in the interpreter of
their structure.

A STACK binding (type LBIND) is created with the BIND instruction.
BIND does the following:
@begin(itemize)
Creates an LBIND and places it on the STACK

Points this new LBIND to the previous LBIND on the STACK

Updates the internal pointer to the most recent LBIND to be the one just
created. 
@end(itemize)

Code inside MUM does the remainder of the binding process, including
pointing the LBIND at the ATOM which is being bound and placing values
and declarations in the LBIND.  Additionally, an LBIND for a given ATOM
is pointed to the previous LBIND for that ATOM.  A number of MIM
instructions perform 'unbinding' of @b(ATOM)s (e.g. RETURN, RTUPLE, and
AGAIN) back to a given FRAME.
The steps in 'unbinding' are:
@begin(itemize)
Remove the LBIND from the STACK

Update the internal pointer to the most recent LBIND to be the previous
LBIND (as saved by the BIND instruction)

Update the LBIND slot of the ATOM pointed to by the LBIND to be the
previous LBIND (if any) for that ATOM.
@end(itemize)

@section<MIM Garbage Collector>

It is intended that MDL have two garbage collectors, a mark-sweep
garbage collector, and a full-copy garbage collector.  MIM instructions
for both are included in this document.

@section<MIM Bootstrap Routine>

In order for any @b(MSUBR) to run, it is necessary for MIM to have
'read' that @b(MSUBR).  Therefore, MIM must include a primitive MDL
reader, which must be capable of parsing the following MDL data types:
@b(IMSUBR), @b(MSUBR), @b(MCODE), @b(ATOM), @b(FIX), @b(FLOAT), @b(STRING),
@b(VECTOR), @b(LIST), and @b(CHARACTER).  By convention, the file
BOOT.MSUBR contains the bootstrap routines for loading a MDL.  The BOOT
file is a sequence of @b(MSUBR)s.  MIM must read these @b(MSUBR)s and
SETG the names of the @b(MSUBR)s accordingly (by convention, the name
of an @b(MSUBR) is the second element of the @b(MSUBR)).  Execution
commences with MIM CALLing the @b(MSUBR) named BOOT.  

@chapter<The MDL Interpreter Written in MDL - MUM>
@section<Overview>

@b(MUM) (@b(M)DL @b(U)nder @b(M)DL) is the name given to the MDL
interpreter which is written in MDL.  In most respects, MUM/MDL will be
identical to the current PDP-10 and TOPS-20 MDLs.  @b(MUM) will,
however, include some capabilities not found in the older MDLs.

@section<Modularity of the MDL Interpreter>

The new MDL interpreter (@b(MUM)) is composed of individual speCialty
modules (e.g. PRINT, READ, ASOC, ARITH).  Each od these modules consists
of`@b(MSUBB)s, as wnulD any other piece of user-code'.  The result is
that the`distinction`between interpreter And 'user-code' `as become
blurrmd.  To tie casual MDL user, thE interpreter will probably appear
lareer than $ib-YB10 version, because some parts of the MDL
environment will be included.  However, to the production-systems
prWS^itSK` wsY^ eaS`t I_BexGldeQCy _lFalhZf 	QJ MY
imiHrpEKlerA]bomAEHinNAXoaYKJ, YK@vimNBa G[@llKdFanHABlec]Nr Wsbte:\efec	S^n>)M S[dlekK^taSZn>J
@QTOjS` aeJFstekFtuEKd w\AbriKitpeRZRDRAlit`AJouDALlmsKZdsTAF
IFalQAVnd]H (DPLBS
))AD gIBalQEVnd]H (DPGBS
))PAB pCXe$Qb)"INNRP,!S]H aA b(/ISXVX ECierQ_H taJ@fiegh!t^Belc[NntABanZDlsN@e A b(]EBXFinYSGctS]H tQCh!tQK`e!CfFnoQY\caA^r Y\baXbi]IPNg\ D@b!LIW Ts aCje IQR scSJ siejctkeH aCb(c)M)V\B L_iH tCh
DRATOQs G]N @QBLC',)sQCde ]_bmAHAIMAgjruginreFAhhiWPDcaABEe[PniAkXatKHDasQC`e OiPerAgjrugihreV\F TQSf aIYXwsCXl 	!" oo@ support for
@b(AT_M)s and @b(OBLIST)c to Be wsitteN in MDL itself whth calls to NTH,	
REST, etc.

The BIND instruction creates and returns an @b(LBIND) ol the STACK.
There is no need for a GBIND instruction, as a @b(GBIND) can be created
with the RECORD instruction.  As with @b(ATOM)s, @b(LBIND)s and
@b(BIND)s are primtype @b(RECORD)s which can be manipulated; thus, the
SUBR's SET and SETG turn into PUTs, as doH @DECL, and GDECL.

@section<Arithmetic and Bktwise Operations>

@b(FIX) is the only non-structured MIM primtype,!replacing the primtype WORD
in the current MDL.  All bitwise operations take any primtype @b(FIX) and
return a type @b(FIX).  The aritHmetic iNstructions take either pairs of
@b(FIX)es or @b(FLOAT)s and return objects of the same type.

@section<I/O>

MIM provides a very primitive I/O interface, which consists of OPEN,
CLOSE, and ctring read/print.  The MDL conversion I/O SUBRs (READ,
READCHR, PRILT, PRIN1, PRINC, PARSE, and UNPARE) have all been written
uskng only these operapions.  Block-iode I/O SUBRs (PRINTB( READB,
PRINTSTRING, READSTRING) can also be!easily incorporated hnto this scheme.  

While these SUBRs cover mcNy MDL I/O applIcations, snme others will nEed
tn be levised.  Akong these is some form of core-image I/O, which
would provide fast, non-parsed I/O, and some machine-independent MDL I/O
scheme, which is being devised by an undergraduate at the present time.

The SAVE and RESTORE instructions provide the means for saving and
restoring a core-image, and is used mostly in the creation of large
subsystems.

@section<Associations>

There is no support in MIM for associative storage as implemented
in the existing MDL.  However, such a scheme has been implemented
in MDL. 

@section<Coroutines>

There is no coroutine/multiprocess facility in MIM.  The major issue
that coroutines encounter is that of the STACK, whether there should
be one for each coroutine, etc.  The possible inclusion of this
concept into the design of MIM will be considered at a later date.

@section<Interrupt Handling>

MIM has a very primitive interrupt system which interacts with a rather
sophisticated software interrupt system written in MDL, and based on the
old MDL's interrupt system.  When a non-emergent interrupt is received by
MIM, MIM CALLs the @b(MSUBR) specified by the SETS ICALL instruction
with one argument, a @b(FIX) between 0 and 35, which is the unique
identifier of that class of interrupt.  

To allow for terminal interrupts, the MIM instruction ATIC (Activate
Terminal Interrupt Character) takes a @b(CHARACTER) and returns a
@b(FIX) which is the unique identifier for a terminal interrupt on that
@b(CHARACTER).

Emergency interrupts (stack overflow, illegal memory read/write) may
require MIM to take some emergency action prior to CALLing the software
interrupt system.  Naturally, these interrupts are somewhat
machine-dependent, and will have to be dealt with for each target machine. 
l
@chapter<MIM Instruction Set>
@section<Stack Operations & Flow of Control>
@begin<format>
@b<PUSH>@\@i<any:any>
@begin<ins>
The PUSH instruction @i<pushs> its operand onto STACK.  The special destination
STACK for other instructions is another of placing objects on the stack.
@end<ins>

@b<POP>@\@i<local>
@begin<ins>
The POP instruction @i<pop>s the top element from the STACK
and moves it into a local variable.  Calling an MSUBR also removes the
arguments from the stack.

@end<ins>

@b<SET>@\@i<local:any>,@i<any:any>
@begin<ins>
The various SET instructions set a local variable to the value of
another local variable or a constant.
The use of local variable as destination also causes a SET of that variable
to occur. 
@end<ins>

@b<SETLR>@\@i<local:any1>,@i<local:frame>,@i<local:any2>
@begin<ins>
Sets local variable @i(any1) in the current frame to the value of
local variable @i(any2) in @i(frame).
@end<ins>

@b<SETRL>@\@i<local:frame>,@i<local:any1>,@i<local:any2>
@begin<ins>
Sets local variable @i(any1) in @i(frame) to the value of local variable
@i(any2) in the current frame.
@end<ins>

@b<ADJ>@\@i<any:fix>
@begin<ins>
Adjusts the STACK by @i<fix> objects, positive indicating @i<push>ing
and negative indicating @i<pop>ping.
@end<ins>

@b<FRAME>@\@i<no operands>
@begin<ins>
Creates a CALL @i<frame> on the STACK.
@end<ins>

@b<CFRAME>@\@i<no operands>
@begin<ins>
Returns the running @i<frame>.
@end<ins>

@b<ARGS>@\@i<any:frame>
@begin<ins>
Returns a TUPLE with the arguments to the @i<frame>.
@end<ins>

@b<TUPLE>@\@i<any:fix>
@begin<ins>
Returns a TUPLE containing @i<fix> elements from the top of the STACK.
@end<ins>

@b<RFRAME>@\@i<any:frame>
@begin<ins>
The return instruction which follows will cause values to be
returned to @i<frame>. Unbinding will occur back to @i<frame>.
@end<ins>

@b<CALL>@\@i<any:atom>,@i<local:fix>
@begin<ins>
Starts execution of an MSUBR.  This instruction must follow the
creation of a FRAME and the PUSHing of arguments.  If the global
value of @i(atom) is an MSUBR, execution starts immediately.  Otherwise,
the NCALL routine is executed.
@end<ins>

@b<INCALL>@\@i<local:any>
@begin<ins>
Builds a FRAME and performs a 'CALL' within the current MSUBR.  This is
useful for PROGs and REPEATs that have external ACTIVATIONS that maybe
RETURNed from or AGAINed.
@end<ins>

@b<MAKTUP>@\@i<local:any1>,@i<local:any2>...@i<local:anyn>
@begin<ins>
Builds and returns a TUPLE out of the arguments passed to an MSUBR.  The
arguments are the temporaries used in the MSUBR.
@end<ins>

@b<ACTIVATION>@\@i<no operands>
@begin<ins>
Saves the current offset into the MSUBR as the 'activation' for the
current FRAME.
@end<ins>

@b<AGAIN>@\@i<local:frame>
@begin<ins>
AGAIN restarts execution of the MSUBR running in @i<frame> from
the offset specified within that MSUBR by a call to ACTIVATION.
Unbinding will occur back to @i<frame>.
@end<ins>

@b<RETURN>@\@i<local:any>,@<local:frame>
@begin<ins>
Performs a CALL return with value as specified by the operand . 
The second argument is optional and defaults to the current frame.
Unbinding for will occur.
@end<ins>

@b<RTUPLE>@\@i<local:fix>
@begin<ins>
Performs a CALL return with any number of values, which have been
PUSHed onto the STACK, and whose number is specified by @i<fix>,
returning as the top of STACK a @i<tuple> pointing to the return values.
@end<ins>
 
@b<JUMP>@\@i<label>
@begin<ins>
Unconditional branch to label.  JUMPs may only be used
locally (i.e. within an @i<msubr>).
@end<ins>
@end<format>

@newpage
@section<GC Interface>
@begin<format>
@b<MARKL>@\@i<local:list>,@i<local:fix>
@b<MARKU(U/V/S)>@\@i<local:ublock>,@i<local:fix>
@b<MARKR>@\@i<local:record>,@i<local:fix>
@begin<ins>
Marks a structure, setting to mark bit to @i(fix), which should be
either zero, one, or a "new address" for copy GC.  MARKL marks just one
element of the @i(list).
@end<ins>

@b<MARKL?>@\@i<local:list>,@i<constant:fix>
@b<MARKU(U/V/S)?>@\@i<local:ublock>,@i<constant:fix>
@b<MARKR?>@\@i<local:record>,@i<constant:fix>
@begin<ins>
Predicate, testing the marked state of a structure.  Unlike normal predicates,
these return either a fix or false.  The second argument is optional, its
existance indicates a relocation should be returned for marked objects.
@end<ins>

@b<SWNEXT>@\@i<local:any>
@begin<ins>
Performs the sweep phase of the garbage collector.
@end<ins>
@b<NEXTS>@\@i<local:fix>
@begin<ins>
Gets and returns a fix that can be used with CONTENTS to get the next item
on the stack.  For marking the stack.
@end<ins>
@b<CONTENTS>@\@i<local:fix>
@begin<ins>
Returns the next stack item.  The argument should be one received from NEXTS.
@end<ins>
@b<PUTS>@\@i<local:fix>,@i<local:any>
@begin<ins>
The opposite of CONTENTS, PUTS stores back into the stack.
@end<ins>
@b<ALLOCL>@\@i<local:fix>,@i<local:any>
@b<ALLOCU(U/V/S)>@\@i<local:fix>,@i<local:any>
@b<ALLOCR>@\@i<local:fix>,@i<local:any>
@begin<ins>
Allocates room for the object specified by the second argument at the address
specified by the first.
@end<ins>
@b<BLT>@\@i<local:fix>,@i<local:fix>,@i<local:fix>
@begin<ins>
Moves an object from the location specified by the first argument to the
location specified by the second argument.  The third argument is the length
in words (32 or 36 bit words).  This length should include the dopewords. 
@end<ins>
@b<RELL>@\@i<local:list>
@b<RELU(U/V/S)>@\@i<local:ublock>
@b<RELR>@\@i<local:record>
@begin<ins>
These instructions recycle the appropriate objects.
@end<ins>

@end<format>

@newpage
@section<Utility>
@begin<format>
@b<HALT>@\@i<no operands>
@begin<ins>
Halts MDL.
@end<ins>

@b<OBJECT>@\@i<local:fix>,@i<local:fix>,@i<local:fix>
@begin<ins>
Returns a MIM object, whose type, length, and value words are the three
operands, respectively.
@end<ins>

@b<GETS>@\@i<byte:fix>
@begin<ins>
Returns the value for the internal variable indicated by @i(fix).
@end<ins>

@b<SETS>@\@i<byte:fix>,@i<local:any>
@begin(ins)
Sets the value of the internal variable indicated by @i(fix) to @i(any).
@end(ins)

@end<format>



@newpage
@section<Type Manipulation>
@begin<format>
@b<TYPE>@\@i<local:any>
@begin<ins>
Returns the TYPE of @i<any>, as a @i<fix>.
@end<ins>

@b<TYPE?>@\@i<local:any>,@i<local:fix>
@b<TYPEW?>@\@i<local:any>,<word>
@begin<ins>
Predicate on TYPE of @i<any> being @i<fix>
@end<ins>

@b<CHTYPE>@\@i<local:any>,@i<local:fix>
@begin<ins>
Returns @i<any>, with its TYPE changed to @i<fix>.
@end<ins>

@b<NEWTYPE>@\@i<local:fix>
@begin<ins>
Returns a @i<fix>, a new TYPE whose primtype is the primtype of @i<fix>.
@end<ins>

@b<VALUE>@\@i<local:any>
@begin<ins>
Returns the 'value' 32 bits of @i<any>, as a @i<fix>.  This is
a utility instruction.
@end<ins>
@end<format>

@newpage
@section<Structure Creation>
@begin<format>
@b<LIST>@\@i<local:fix>
@b<LISTB>@\@i<byte>
@begin<ins>
LIST creates and returns a LIST containing @i<fix> elements which
are on the top of the STACK.
@end<ins>

@b<UBLOCK>@\@i<local:fix,local:fix,local:fix>
@b<UBLOCKB>@\@i<local:fix,local:fix,byte>
@begin<ins>
UBLOCK creates and returns a UBLOCK of the specified type (@i<fix1>),
with @i<fix2> elements from the top of the STACK.
@end<ins>

@b<RECORD>@\@i<local:fix,local:fix>
@b<RECORDB>@\@i<local:fix,byte>
@begin<ins>
RECORD creates and returns a RECORD of the specified type (@i<fix1>),
with @i<fix2> elements from the top of the STACK.
@end<ins>
@end<format>

@newpage
@section<Structure Manipulation>
@begin<format>
@b<NTHL>@\@i<local:list>,@i<local:fix>
@b<NTHLB>@\@i<local:list>,@i<byte>

@b<NTHR>@\@i<local:record>,@i<local:fix>
@b<NTHRB>@\@i<local:record>,@i<byte>

@b<NTHU>@\@i<local:ublock>,@i<local:fix>,@i<local:any>
@b<NTHUB>@\@i<local:ublock>,@i<byte>,@i<local:any>
@begin<ins>
Returns the @i<fix>th element of @i<structure>.
@end<ins>

@b<LENL>@\@i<local:list>
@b<LENR>@\@i<local:record>
@b<LENU>@\@i<local:ublock>
@begin<ins>
Returns the length of @i<structure>, as a @i<fix>.
@end<ins>

@b<EMPL?>@\@i<local:list>
@b<EMPR?>@\@i<local:record>
@b<EMPV?>@\@i<local:ublock>
@begin<ins>
Predicate on emptiness of @i<structure>.
@end<ins>

@b<PUTL>@\@i<local:list>,@i<local:fix>,@i<local:any>
@b<PUTLB>@\@i<local:list>,@i<byte>,@i<local:any>

@b<PUTR>@\@i<local:record>,@i<local:fix>,@i<local:any>
@b<PUTRB>@\@i<local:record>,@i<byte>,@i<local:any>

@b<PUTU>@\@i<local:ublock>,@i<local:fix>,@i<local:any>
@b<PUTUB>@\@i<local:ublock>,@i<byte>,@i<local:any>
@begin<ins>
Makes @i<any> the @i<fix>th element of @i<structure>.
@end<ins>


@b<RESTL>@\@i<local:list>,@i<local:fix>
@b<RESTLB>@\@i<local:list>,@i<byte>

@b<RESTU>@\@i<local:ublock>,@i<local:fix>,@i<local:any>
@b<RESTUB>@\@i<local:ublock>,@i<byte>,@i<local:any>
@begin<ins>
Rests @i<structure> by @i<fix> elements.
@end<ins>


@b<BACKU>@\@i<local:ublock>,@i<local:fix>
@b<BACKUB>@\@i<local:ublock>,@i<byte>
@begin<ins>
Returns @i<ublock> with @i<fix> previously RESTUed elements
replaced.
@end<ins>

@b<TOPU>@\@i<local:ublock>
@begin<ins>
Returns @i<ublock> with all previously RESTUed elements restored.
@end<ins>

@b<CONS>@\@i<local:any>,@i<local:list>
@begin<ins>
Returns a @i<list>, with @i<any> consed onto @i<primtype list>.
@end<ins>

@b<PUTREST>@\@i<local:list1>,@i<local:list2>
@begin<ins>
Returns @i<list1>, after making REST of it be @i<list2>.
@end<ins>
@end<format>

@newpage
@section<ATOM-Related Operations>
@begin<format>
@b<BIND>@\@i<no operand>
@begin<ins>
Creates and returns a BINDING on the STACK.
@end<ins>

@b<UNBIND>@\@i<local:lbind>
@begin<ins>
Unbinds STACK bindings until the top binding is @i(lbind).
@end<ins>

@b<FIXBIND>@\@i<no operands>
@begin<ins>
Ensures that each @t(ATOM) pointed to by a STACK binding points
back at that binding.
@end<ins>

@b<SETG>@\@i<local:atom>,@i<local:any>
@begin<ins>
Assumes that a global binding exists for @i(atom): stuffs @i(any) into
that global binding's value slot.
@end<ins>

@b<GVAL>@\@i<local:atom>
@begin<ins>
Assumes that a global binding exists for @i(atom): returns that global
binding's value slot.
@end<ins>

@end<format>

@newpage
@section<Input/Output>
@begin<format>

@b<OPEN>@\@i<local:fix1>,@i<local:fix2>,@i<local:string>
@begin<ins>
Opens a 'channel' to a file specified by @i(string).  Note
that the format of @i<string> is completely machine-dependent.
The direction of the 'channel' is specified by @i(fix1): 1 is 'print',
0 is 'read'.  The byte-size of the 'channel' is specified by @i(fix2):
usually this will be for character I/O (7 or 8) or word I/O (32 or 36).
The byte-size will be used by the READ and PRINT instructions in
determining the unit of I/O.
 
Returns a @i<fix>, a unique 'channel' designator, or a @i<false>
containing an error code (a @i(fix)).
@end<ins>

@b<CLOSE>@\@i<local:fix>
@begin<ins>
Closes the 'channel' associated with @i<fix>, a 'channel' designator.
@end<ins>

@b<READ>@\@i<local:fix1>,@i<local:string>,@i<local:fix2>
@begin<ins>
Reads @i(fix2) items from 'channel' with identifier @i(fix1) into
@i(string). 
@end<ins>
 
@b<PRINT>@\@i<local:fix1>,@i<local:string>,@i<local:fix2>
@begin<ins>
Prints @i(fix2) items to 'channel' with identifier @i(fix1) from
@i(string). 
@end<ins>
 
@b<SAVE>@\@i<local:fix>
@begin<ins>
Saves the state of MDL on 'channel' @i<fix>.
@end<ins>

@b<RESTORE>@\@i<local:fix>
@begin<ins>
Restores the state of MDL from 'channel' @i<fix>.
@end<ins>
@end<format>

@newpage
@section<Arithmetic>
The following arithmetic instructions return the result of the
appropriate operation.
@begin<format>

@b<ADD>@\@i<local:fix>,@i<local:fix>
@b<ADDB>@\@i<local:fix>,@i<byte>
@b<ADDF>@\@i<local:float>,@i<local:float>

@b<SUB>@\@i<local:fix>,@i<local:fix>
@b<SUBB>@\@i<local:fix>,@i<byte>
@b<SUBF>@\@i<local:float>,@i<local:float>

@b<MUL>@\@i<local:fix>,@i<local:fix>
@b<MULB>@\@i<local:fix>,@i<byte>
@b<MULF>@\@i<local:float>,@i<local:float>

@b<DIV>@\@i<local:fix>,@i<local:fix>
@b<DIVB>@\@i<local:fix>,@i<byte>
@b<DIVF>@\@i<local:float>,@i<local:float>


@b<RANDOM>@\@i<local:fix>
@begin<ins>
Selects a RANDOM number between one and @i<fix>, inclusive.
@end<ins>


@b<FIX>@\@i<local:float>
@begin<ins>
Turns @i<float> into a @i<fix>.
@end<ins>

@b<FLOAT>@\@i<local:fix>
@begin<ins>
Turns @i<fix> into a @i<float>.
@end<ins>
@end<format>

The following are arithmetic conditional branch instructions.
@begin<format>

@b<GRTR?>@\@i<local:fix>,@i<local:fix>
@b<GRTRB?>@\@i<local:fix>,@i<byte>

@b<LESS?>@\@i<local:fix>,@i<local:fix>
@b<LESSB?>@\@i<local:fix>,<byte>
@end<format>

@newpage
@section<Bitwise Operations>
All of the following instructions take two operands of primtype @i<fix>
and return a type @i<fix>.
@begin<format>

@b<AND>@\@i<local:fix>,@i<local:fix>

@b<IOR>@\@i<local:fix>,@i<local:fix>

@b<XOR>@\@i<local:fix>,@i<local:fix>

@b<EQV>@\@i<local:fix>,@i<local:fix>

@b<LSH>@\@i<local:fix>,@i<local:fix>

@b<ROT>@\@i<local:fix>,@i<local:fix>
@end<format>

@newpage
@section<General Predicates>
@begin<format>
@b<EQUAL?>@\@i<local:any>,@i<local:any>
@begin<ins>
Conditional branch on equality of operands (i.e. ==? in the MDL sense).
@end<ins>

@b<VEQUAL?>@\@i<local:any>,@i<local:any>
@b<VEQB?>@\@i<local:any>,@i<byte>
@begin<ins>
Conditional branch on equality of 'value' words of operands only.
@end<ins>
@end<format>

@appendix<Sample MIM Assembly Code>

The following examples give representitive MDL code with the
corresponding MIM code, in assembly format.  Those familiar with the
PDP-10 MDL assembler format will be comfortable reading it. Basically,
each instruction is a @b(FORM), whose first element is an operation code
mnemonic, and whose remaining elements up to but not including the
special characters -, +, and = are operand descriptors.  Local operands
are denoted by 'names' (i.e. @b(ATOM)s). @b(MSUBR) operands can be any legal
MDL object (including @b(ATOMs), and are specified as the MDL object itself
(except for @b(ATOM)s, which are specified as '<name>). Predicate
instructions are followed by a word which describes a pc-relative jump
if the instruction succeeds or fails.  A + precedes a label to jump to
if a predicate condition succeeds; a - precedes a label to jump to if
the condition fails.  Instructions which return a value are followed by
a byte which describes the local variable in which to store the return
value.  This is described by the syntax = 'name' where 'name', as
before, is an @b(ATOM).  If an operation which returns a value does not have
an = 'name' or is the @b(ATOM) STACK, the value will be pushed on the
STACK. 

The pseudo-op FCN defines an @b(MSUBR), and is followed by the name of
the @b(MSUBR), its argument declaration (a @b(LIST)) and names of it's
arguments. The pseudo-op TEMP allocates temporary variables on the STACK.

Please note that the distinction between such operations as CALL and
CALLB is not made in assembly syntax.  The assember will generate the
correct instruction.  Similarly, all STACK-type operations will be
listed in their generic form (e.g. PUSH, SET).  This is for clarity
and readability.
 
@newpage
@begin<verbatim>
@appendixsection<Simple MAPF>

MDL:

<DEFINE FOO (L)
        #DECL ((L) LIST)
        <MAPF ,LIST ,BAR .L>>

MIM:

        <FCN    FOO ("VALUE" LIST LIST) L>
        <TEMP   TMP0>
        <EMPL?  L + END>
LOOP    <NTHL   L 1>
        <CALL   'BAR 1>
        <INC    TMP0>
	<RESTL  L 1 = L>
        <EMPL?  L - LOOP>
END     <LIST   TMP0>
        <RETURN STACK>
        
@newpage
If the argument to the function FOO were not DECLed, i.e. could
be either a primtype LIST, RECORD, or UBLOCK, the following
would result:

        <FCN    FOO ("VALUE" LIST STRUCTURED) X>
        <TEMP   TMP0 TMP1 TMP2>
        <FRAME>
        <PUSH   X>
        <CALL   'EMPTY? 1 = TMP2>
        <TYPE?  TMP2 <TYPE-WORD FALSE> + END>
LOOP    <FRAME>
        <PUSH   X>
        <PUSH   1>
        <CALL   'NTH 2 = TMP1>
        <FRAME>
        <PUSH   TMP1>
        <CALL   'BAR 1>
        <INC    TMP0>
        <FRAME>
        <PUSH   X>
        <PUSH   1>
        <CALL   'REST 2 = X>
        <PUSH   X>
        <CALL   'EMPTY? 1 = TMP2>
        <TYPE?  TMP2 <TYPE-WORD FALSE> - LOOP>
END     <LIST   TMP0>
        <RETURN STACK>

@appendixsection<Recursive Factorial Function>

MDL:

<DEFINE FACT (N)
        <COND (<L=? .N 1> 1)
              (T
               <* .N <FACT <- .N 1>>>)>>

MIM:

        <FCN    FACT ("VALUE" FIX FIX) N>
        <TEMP	TMP1>
	<GRTR?  N 1 - LBL>
        <FRAME>
	<SUB    N 1 = STACK>
        <CALL   'FACT 1 = TMP1>                
        <MUL    N TMP1 = TMP1>
        <RETURN TMP1>
LBL     <RETURN 1>
        
@end<verbatim>
         