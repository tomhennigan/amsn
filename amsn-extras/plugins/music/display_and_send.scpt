FasdUAS 1.101.10   ��   ��  
  k           
  l     �� ��    D > by Edgar C. Rodriguez, Daniel Buenfil and J�r�me Gagnon-Voyer       	
  l     �� 
��   
 ] WiTunes script to get Path and Name of current track playing and write it to a text file    	   
  l     ������  ��     
 
 
 l     ������  ��      
  l     ��
  O       
  r      
  l    ��
  I   �� ��
�� .corecnte****       ****
  l    ��
  6     
  2   ��
�� 
pcap
  l    ��
  =     
  1   	 ��
�� 
pnam
  m        iTunes   ��  ��  ��  ��  
  o      ���� 0 itunes iTunes
  m       �null      � ��  �System Events.app�
(      z���п�� �	xԿ��p    ��          sevs   alis    z  Tiger                      �J��H+    �System Events.app                                                j��s�        ����  	                CoreServices    �K1      ����      �  �  �  3Tiger:System:Library:CoreServices:System Events.app   $  S y s t e m   E v e n t s . a p p    T i g e r  -System/Library/CoreServices/System Events.app   / ��  ��       !
   l     ������  ��   !  " #
 " l  � $��
 $ Z   � % &�� '
 % ?    ( )
 ( o    ���� 0 itunes iTunes
 ) m    ����  
 & k   d * *  + ,
 + l   ������  ��   ,  - .
 - O   b / 0
 / k   "a 1 1  2 3
 2 r   " 1 4 5
 4 b   " - 6 7
 6 l  " + 8��
 8 I  " +�� 9 :
�� .earsffdralis        afdr
 9 m   " #��
�� afdmasup : �� ; <
�� 
from
 ; m   $ %��
�� fldmfldu < �� =��
�� 
rtyp
 = m   & '��
�� 
utxt��  ��  
 7 m   + , > >  amsn:plugins:actualsong   
 5 o      ���� 0 fsong fSong 3  ? @
 ? Q   2 E A B��
 A I  5 <�� C��
�� .rdwrclosnull���     ****
 C o   5 8���� 0 fsong fSong��  
 B R      ������
�� .ascrerr ****      � ****��  ��  ��   @  D E
 D I  F Q�� F G
�� .rdwropenshor       file
 F o   F I���� 0 fsong fSong G �� H��
�� 
perm
 H m   L M��
�� boovtrue��   E  I J
 I I  R ]�� K L
�� .rdwrseofnull���     ****
 K l  R U M��
 M o   R U���� 0 fsong fSong��   L �� N��
�� 
set2
 N m   X Y����  ��   J  O P
 O I  ^ u�� Q R
�� .rdwrwritnull���     ****
 Q b   ^ e S T
 S m   ^ a U U  iTunes   
 T o   a d��
�� 
ret  R �� V W
�� 
refn
 V o   h k���� 0 fsong fSong W �� X��
�� 
wrat
 X m   n q��
�� rdwreof ��   P  Y Z
 Y l  v v�� [��   [ S Mif iTunes is playing, return the artist, the song name and the path (in Unix)    Z  \ ]
 \ Z   v_ ^ _ `��
 ^ =  v  a b
 a 1   v {��
�� 
pPlS
 b m   { ~��
�� ePlSkPSP
 _ k   �� c c  d e
 d I  � ��� f g
�� .rdwrwritnull���     ****
 f b   � � h i
 h m   � � j j 
 Play   
 i o   � ���
�� 
ret  g �� k l
�� 
refn
 k o   � ����� 0 fsong fSong l �� m��
�� 
wrat
 m m   � ���
�� rdwreof ��   e  n o
 n Z   �� p q r��
 p =  � � s t
 s n   � � u v
 u m   � ���
�� 
pcls
 v 1   � ���
�� 
pTrk
 t m   � ���
�� 
cURT
 q k   � w w  x y
 x r   � � z {
 z n   � � | }
 | 1   � ���
�� 
pnam
 } 1   � ���
�� 
pTrk
 { o      ���� 0 asong aSong y  ~ 
 ~ r   � � � �
 � m   � �����  
 � o      ���� 
0 	finalpath     � �
 � I  � ��� � �
�� .rdwrwritnull���     ****
 � b   � � � �
 � o   � ����� 0 asong aSong
 � o   � ���
�� 
ret  � �� � �
�� 
refn
 � o   � ����� 0 fsong fSong � �� � �
�� 
as  
 � m   � ���
�� 
TEXT � �� ���
�� 
wrat
 � m   � ���
�� rdwreof ��   �  � �
 � I  � ��� � �
�� .rdwrwritnull���     ****
 � b   � � � �
 � m   � � � �      
 � o   � ���
�� 
ret  � �� � �
�� 
refn
 � o   � ����� 0 fsong fSong � �� � �
�� 
as  
 � m   � ���
�� 
TEXT � �� ���
�� 
wrat
 � m   � ���
�� rdwreof ��   �  � �
 � I  ��� � �
�� .rdwrwritnull���     ****
 � b   � � �
 � o   � ����� 
0 	finalpath  
 � o   ���
�� 
ret  � �� � �
�� 
refn
 � o  	���� 0 fsong fSong � �� ���
�� 
wrat
 � m  ��
�� rdwreof ��   �  ���
 � I �� ���
�� .rdwrclosnull���     ****
 � o  ���� 0 fsong fSong��  ��   r  � �
 � = + � �
 � n  ' � �
 � m  #'��
�� 
pcls
 � 1  #��
�� 
pTrk
 � m  '*��
�� 
cShT �  � �
 � k  .� � �  � �
 � r  .9 � �
 � n  .5 � �
 � 1  35��
�� 
pnam
 � 1  .3��
�� 
pTrk
 � o      ���� 0 asong aSong �  � �
 � r  :G � �
 � n  :C � �
 � 1  ?C��
�� 
pArt
 � 1  :?��
�� 
pTrk
 � o      ���� 0 aart aArt �  � �
 � r  HM � �
 � m  HI����  
 � o      ���� 
0 	finalpath   �  � �
 � I Ne�� � �
�� .rdwrwritnull���     ****
 � b  NU � �
 � o  NQ���� 0 asong aSong
 � o  QT��
�� 
ret  � �� � �
�� 
refn
 � o  X[���� 0 fsong fSong � �� ���
�� 
wrat
 � m  ^a��
�� rdwreof ��   �  � �
 � I f�� � �
� .rdwrwritnull���     ****
 � b  fm � �
 � o  fi�~�~ 0 aart aArt
 � o  il�}
�} 
ret  � �| � �
�| 
refn
 � o  ps�{�{ 0 fsong fSong � �z � �
�z 
as  
 � m  vy�y
�y 
TEXT � �x ��w
�x 
wrat
 � m  |�v
�v rdwreof �w   �  � �
 � I ���u � �
�u .rdwrwritnull���     ****
 � b  �� � �
 � o  ���t�t 
0 	finalpath  
 � o  ���s
�s 
ret  � �r � �
�r 
refn
 � o  ���q�q 0 fsong fSong � �p ��o
�p 
wrat
 � m  ���n
�n rdwreof �o   �  ��m
 � I ���l ��k
�l .rdwrclosnull���     ****
 � o  ���j�j 0 fsong fSong�k  �m   �  � �
 � = �� � �
 � n  �� � �
 � m  ���i
�i 
pcls
 � 1  ���h
�h 
pTrk
 � m  ���g
�g 
cCDT �  � �
 � k  �7 � �  � �
 � r  �� � �
 � n  �� � �
 � 1  ���f
�f 
pnam
 � 1  ���e
�e 
pTrk
 � o      �d�d 0 asong aSong �  � �
 � r  �� � �
 � n  �� � �
 � 1  ���c
�c 
pArt
 � 1  ���b
�b 
pTrk
 � o      �a�a 0 aart aArt �  � �
 � r  �� � �
 � m  ���`�`  
 � o      �_�_ 
0 	finalpath   �  � �
 � I ���^ � �
�^ .rdwrwritnull���     ****
 � b  �� � �
 � o  ���]�] 0 asong aSong
 � o  ���\
�\ 
ret  � �[ � �
�[ 
refn
 � o  ���Z�Z 0 fsong fSong � �Y � �
�Y 
as  
 � m  ���X
�X 
TEXT � �W ��V
�W 
wrat
 � m  ���U
�U rdwreof �V   �  
  I ��T
�T .rdwrwritnull���     ****
 b  ��
 o  ���S�S 0 aart aArt
 o  ���R
�R 
ret  �Q
�Q 
refn
 o  �P�P 0 fsong fSong �O	
�O 
as  
 m  �N
�N 
TEXT	 �M
�L
�M 
wrat

 m  �K
�K rdwreof �L   
 I /�J

�J .rdwrwritnull���     ****

 b  
 o  �I�I 
0 	finalpath  
 o  �H
�H 
ret  �G
�G 
refn
 o  "%�F�F 0 fsong fSong �E�D
�E 
wrat
 m  (+�C
�C rdwreof �D   �B
 I 07�A�@
�A .rdwrclosnull���     ****
 o  03�?�? 0 fsong fSong�@  �B   � 
 = :G
 n  :C
 m  ?C�>
�> 
pcls
 1  :?�=
�= 
pTrk
 m  CF�<
�< 
cFlT �;
 k  J� 
 r  JY !
  c  JU"#
" n  JQ$%
$ 1  OQ�:
�: 
pnam
% 1  JO�9
�9 
pTrk
# m  QT�8
�8 
ctxt
! o      �7�7 0 asong aSong &'
& r  Zg()
( n  Zc*+
* 1  _c�6
�6 
pArt
+ 1  Z_�5
�5 
pTrk
) o      �4�4 0 aart aArt' ,-
, r  hu./
. n hq01
0 1  mq�3
�3 
pLoc
1 1  hm�2
�2 
pTrk
/ o      �1�1 
0 	firstpath  - 23
2 Z  v�45�06
4 > v}78
7 o  vy�/�/ 
0 	firstpath  
8 m  y|�.
�. 
msng
5 r  ��9:
9 c  ��;<
; n  ��=>
= 1  ���-
�- 
psxp
> o  ���,�, 
0 	firstpath  
< m  ���+
�+ 
TEXT
: o      �*�* 
0 	finalpath  �0  
6 r  ��?@
? m  ���)�)  
@ o      �(�( 
0 	finalpath  3 AB
A I ���'CD
�' .rdwrwritnull���     ****
C b  ��EF
E o  ���&�& 0 asong aSong
F o  ���%
�% 
ret D �$GH
�$ 
refn
G o  ���#�# 0 fsong fSongH �"IJ
�" 
as  
I m  ���!
�! 
TEXTJ � K�
�  
wrat
K m  ���
� rdwreof �  B LM
L I ���NO
� .rdwrwritnull���     ****
N b  ��PQ
P o  ���� 0 aart aArt
Q o  ���
� 
ret O �RS
� 
refn
R o  ���� 0 fsong fSongS �TU
� 
as  
T m  ���
� 
TEXTU �V�
� 
wrat
V m  ���
� rdwreof �  M WX
W I ���YZ
� .rdwrwritnull���     ****
Y b  ��[\
[ o  ���� 
0 	finalpath  
\ o  ���
� 
ret Z �]^
� 
refn
] o  ���� 0 fsong fSong^ �_�
� 
wrat
_ m  ���
� rdwreof �
  X `�
` I ���
a�	
�
 .rdwrclosnull���     ****
a o  ���� 0 fsong fSong�	  �  �;  ��   o bc
b l �����  �  c de
d l �����  �  e f�
f l ���g�  g . (if iTunes is paused, return that message   �   ` hi
h =  	jk
j 1   �
� 
pPlS
k m  � 
�  ePlSkPSpi lm
l k  -nn op
o I #��qr
�� .rdwrwritnull���     ****
q b  st
s m  uu  0   
t o  ��
�� 
ret r ��vw
�� 
refn
v o  ���� 0 fsong fSongw ��x��
�� 
wrat
x m  ��
�� rdwreof ��  p yz
y I $+��{��
�� .rdwrclosnull���     ****
{ o  $'���� 0 fsong fSong��  z |��
| l ,,��}��  } / )if iTunes is stopped, return that message   ��  m ~
~ = 09��
� 1  05��
�� 
pPlS
� m  58��
�� ePlSkPSS ���
� k  <[�� ��
� I <S����
�� .rdwrwritnull���     ****
� b  <C��
� m  <?��  0   
� o  ?B��
�� 
ret � ����
�� 
refn
� o  FI���� 0 fsong fSong� �����
�� 
wrat
� m  LO��
�� rdwreof ��  � ���
� I T[�����
�� .rdwrclosnull���     ****
� o  TW���� 0 fsong fSong��  ��  ��  ��   ] ���
� l ``������  ��  ��  
 0 m    ���null     � ��  
iTunes.app��p( "D�
(      8���0���`�	xԿ���    ��          hook   alis    8  Tiger                      �J��H+    
iTunes.app                                                       �6�28        ����  	                Applications    �K1      �x�        Tiger:Applications:iTunes.app    
 i T u n e s . a p p    T i g e r  Applications/iTunes.app   / ��   . ���
� l cc�����  �  if iTunes is not open   ��  ��  
 ' Q  g����
� k  j��� ��
� r  j���
� I j����
�� .rdwropenshor       file
� b  jw��
� l js���
� I js����
�� .earsffdralis        afdr
� m  jk��
�� afdmasup� ����
�� 
from
� m  lm��
�� fldmfldu� �����
�� 
rtyp
� m  no��
�� 
utxt��  ��  
� m  sv��  amsn:plugins:actualsong   � �����
�� 
perm
� m  z{��
�� boovtrue��  
� o      ���� 0 fsong fSong� ��
� I ������
�� .rdwrseofnull���     ****
� l �����
� o  ������ 0 fsong fSong��  � �����
�� 
set2
� m  ������  ��  � ��
� l �������  � ; 5write originalnick to fSong as string starting at eof   � ��
� I ������
�� .rdwrwritnull���     ****
� b  ����
� m  ����  iTunes   
� o  ����
�� 
ret � ����
�� 
refn
� o  ������ 0 fsong fSong� �����
�� 
wrat
� m  ����
�� rdwreof ��  � ��
� I ������
�� .rdwrwritnull���     ****
� b  ����
� m  ����  0   
� o  ����
�� 
ret � ����
�� 
refn
� o  ������ 0 fsong fSong� �����
�� 
wrat
� m  ����
�� rdwreof ��  � ��
� I �������
�� .rdwrclosnull���     ****
� o  ������ 0 fsong fSong��  � ���
� l ��������  ��  ��  
� R      ����
�� .ascrerr ****      � ****
� o      ���� 0 e  � ����
�� 
errn
� o      ���� 0 n  � ����
�� 
erob
� o      ���� 0 fsong fSong� ����
�� 
errt
� o      ���� 0 t  � �����
�� 
ptlr
� o      ���� 0 p  ��  
� k  ���� ��
� l ��������  ��  � ��
� l �������  � ; 5 errors will leave the file open, so try to close it    � ��
� Q  ������
� I �������
�� .rdwrclosnull���     ****
� o  ������ 0 fsong fSong��  
� R      ������
�� .ascrerr ****      � ****��  ��  ��  � ��
� l ��������  ��  � ���
� R  ������
�� .ascrerr ****      � ****
� o  ������ 0 e  � ����
�� 
errn
� o  ������ 0 n  � ����
�� 
erob
� o  ������ 0 fsong fSong� ����
�� 
errt
� o  ������ 0 t  � �����
�� 
ptlr
� o  ������ 0 p  ��  ��  ��   # ��
� l     ������  ��  � ���
� l     ������  ��  ��       
���������������  � ����������������
�� .aevtoappnull  �   � ****�� 0 itunes iTunes�� 0 fsong fSong�� 0 asong aSong�� 0 aart aArt�� 
0 	firstpath  �� 
0 	finalpath  ��  � �����������
�� .aevtoappnull  �   � ****
� k    ���  ��  "����  ��  ��  � ����~�}�|�� 0 e  � 0 n  �~ 0 fsong fSong�} 0 t  �| 0 p  � B �{��z �y�x��w�v�u�t�s�r�q >�p�o�n�m�l�k�j�i U�h�g�f�e�d�c�b j�a�`�_�^�]�\�[�Z ��Y�X�W�V�U�T�S�R�Q�P�Ou�N�����M��L�K�J�I�H
�{ 
pcap�  
�z 
pnam
�y .corecnte****       ****�x 0 itunes iTunes
�w afdmasup
�v 
from
�u fldmfldu
�t 
rtyp
�s 
utxt�r 
�q .earsffdralis        afdr�p 0 fsong fSong
�o .rdwrclosnull���     ****�n  �m  
�l 
perm
�k .rdwropenshor       file
�j 
set2
�i .rdwrseofnull���     ****
�h 
ret 
�g 
refn
�f 
wrat
�e rdwreof 
�d .rdwrwritnull���     ****
�c 
pPlS
�b ePlSkPSP
�a 
pTrk
�` 
pcls
�_ 
cURT�^ 0 asong aSong�] 
0 	finalpath  
�\ 
as  
�[ 
TEXT�Z 
�Y 
cShT
�X 
pArt�W 0 aart aArt
�V 
cCDT
�U 
cFlT
�T 
ctxt
�S 
pLoc�R 
0 	firstpath  
�Q 
msng
�P 
psxp
�O ePlSkPSp
�N ePlSkPSS�M 0 e  � �G�F�
�G 
errn�F 0 n  � �E�D�
�E 
erob�D 0 fsong fSong� �C�B�
�C 
errt�B 0 t  � �A�@�?
�A 
ptlr�@ 0 p  �?  
�L 
errn
�K 
erob
�J 
errt
�I 
ptlr�H ���� *�-�[�,\Z�81j E�UO�jK�A������ �%E` O _ j W X  hO_ a el O_ a jl Oa _ %a _ a a � O*a ,a  �a  _ %a _ a a � O*a !,a ",a #  v*a !,�,E` $OjE` %O_ $_ %a _ a &a 'a a a ( Oa )_ %a _ a &a 'a a a ( O_ %_ %a _ a a � O_ j Y�*a !,a ",a *  |*a !,�,E` $O*a !,a +,E` ,OjE` %O_ $_ %a _ a a � O_ ,_ %a _ a &a 'a a a ( O_ %_ %a _ a a � O_ j YU*a !,a ",a -  �*a !,�,E` $O*a !,a +,E` ,OjE` %O_ $_ %a _ a &a 'a a a ( O_ ,_ %a _ a &a 'a a a ( O_ %_ %a _ a a � O_ j Y �*a !,a ",a .  �*a !,�,a /&E` $O*a !,a +,E` ,O*a !,a 0,E` 1O_ 1a 2 _ 1a 3,a '&E` %Y jE` %O_ $_ %a _ a &a 'a a a ( O_ ,_ %a _ a &a 'a a a ( O_ %_ %a _ a a � O_ j Y hOPY a*a ,a 4  &a 5_ %a _ a a � O_ j OPY 1*a ,a 6  $a 7_ %a _ a a � O_ j Y hOPUOPY � d������ a 8%a el E` O_ a jl Oa 9_ %a _ a a � Oa :_ %a _ a a � O_ j OPW /X ; < 
�j W X  hO)a =�a >�a ?�a @�a A��� � ��� � T i g e r : U s e r s : g a g n o n j e : L i b r a r y : A p p l i c a t i o n   S u p p o r t : a m s n : p l u g i n s : a c t u a l s o n g�   nobody                  � ���  S k i n d r e d  ��
alis    �   Tiger                      �J��H+   	O
02 nobody.mp3                                                   u�i�        ����  	                
Album inconnu     �K1      �j8�     	O s 
� 
� 
� �7  j4  STiger:Users:gagnonje:Music:iTunes:iTunes Music:Skindred:Album inconnu:02 nobody.mp3    
 0 2   n o b o d y . m p 3    T i g e r  MUsers/gagnonje/Music/iTunes/iTunes Music/Skindred/Album inconnu/02 nobody.mp3   /    ��  � h N/Users/gagnonje/Music/iTunes/iTunes Music/Skindred/Album inconnu/02 nobody.mp3                  ��   ascr  
��ޭ