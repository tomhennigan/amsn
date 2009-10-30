<?php
@setlocale(LC_ALL, 'tr_TR.utf-8');
//header menu definitions START
define('HOME_MENU', 'AnaSayfa');
define('DOWNLOAD_MENU', 'İndir');
define('FEATURES_MENU','Özellikler');
define('SKINS_MENU','DışGörünümler');
define('PLUGINS_MENU','Eklentiler');
define('SCREEN_MENU','EkranGörüntüleri');
define('DOCS_MENU','Belgeler/Yardım');
define('DEV_MENU','Geliştirme');
//header menu definitions END

// index.php definitions START
define('AMSN_DESC', '<strong>aMSN</strong> MSN Messenger\'ın açık kaynak kodlu bir benzeridir, işte bazı özellikleri:
');
define('DESC_OFF_MSG', 'Çevrimdışı Mesajlaşma');
define('VOICE_CLIP', 'Sesli iletiler');
define('DISPLAY_PICS', 'Görüntü resimleri');
define('CUSTOM_EMOS', 'Özel duygu ifadeleri');
define('MULTI_LANG', 'Çoklu dil desteği (Şu anda yaklaşık 40 dil desteklenmektedir)');
define('WEB_CAM_SUPPORT', 'Kamera desteği');
define('SIGNIN_MORE', 'Tek oturumda birden çok hesaba bağlanma');
define('FSPEED_FTRANS', 'Çok hızlı dosya aktarımı');
define('GROUP_SUPPORT', 'Grup desteği');
define('EMOS_WITH_SOUND', 'Hareketsiz, hareketli ve sesli duygu ifadeleri');
define('CHAT_LOGS', 'Sohbet kaydetme');
define('TIMESTAMPING', 'Zaman bildirimi');
define('EVENT_ALARM', 'Olay bildirimi');
define('CONFERENCE_SUPPORT', 'Toplu görüşme desteği');
define('TABBED_CHAT', 'Sekmeli sohbet pencereleri');
define('FOR_FULL_FEATURES', 'Tüm özellikleri görmek için <a href="features.php">Özellikler</a> sayfasını ziyaret ediniz.<a href="plugins.php">Eklentiler</a> ile çok daha fazla özellik ekleyebilir ya da birbirinden farklı <a href="skins.php">Kabuklar</a> ile aMSN görünümünü tamamiyle değiştirebilirsiniz!');
define('DOWN_IMG','aMSN\'yi İndir');
define('PLUG_IMG','Eklenti Al');
define('SKIN_IMG','Kabuk Al');
// index.php definitions END

//download.php definitions START
define('LINUX_DOWN', 'Linux');
define('WIN_DOWN', 'Windows');
define('WIN95_DOWN', 'Windows 95');
define('MACOSX_DOWN', 'Mac OS X(Evrensel)');
define('FREEBSD_DOWN', 'FreeBSD');
define('TARBALL_DOWN', 'Toplu Kaynak Arşivi');
define('LATEST_SVN','En son geliştirme sürümü (Son SVN sürümü');
//download.php definitions END

//features.php definitions START
define('AMSN_DESC_FEAT', '<strong>aMSN</strong>MSN Messenger\'ın açık kaynak kodlu bir benzeridir. Özellikleri şunlardır:');
define('OFF_MSG_FEAT', '&#187; Çevrimdışı Mesajlaşma');
define('VOICE_CLIP_FEAT', '&#187; Sesli İletiler');
define('NLW_FEAT', '&#187; Yeni giriş penceresi ve Kişi listesi (0.97 sürümü ile)');
define('DISPLAY_PICS_FEAT', '&#187; Görüntü Resimleri');
define('CUSTOM_EMOS_FEAT', '&#187; Özel duygu ifadeleri');
define('MULTI_LANG_FEAT', '&#187; Çoklu dil desteği (Şu anda yaklaşık 40 dil desteklenmektedir)');
define('SIGNIN_MORE_FEAT', '&#187; Tek oturumda birden çok hesaba bağlanma');
define('FTRANS_FEAT', '&#187; Dosya Aktarımı');
define('GROUP_SUPPORT_FEAT', '&#187; Grup Desteği');
define('EMOS_WITH_SOUND_FEAT', '&#187; Hareketsiz, hareketli ve sesli duygu ifadeleri');
define('CHAT_LOGS_FEAT', '&#187; Sohbet kaydetme');
define('EVENT_ALARM_FEAT', '&#187; Olay bildirimi');
define('CONFERENCE_SUPPORT_FEAT', '&#187; Toplu görüşme desteği');
define('WEB_CAM_SUPPORT_FEAT', '&#187; Kamera desteği');
define('HISTORY_FEAT', '&#187; Renkli sohbet geçmişi gösterimi');
define('AUTOCLOSE_FEAT', '&#187; Dosya aktarım penceresinde, dosya alımı tamamlandığında kendiliğinden kapanma özelliği ');
define('PLUGIN_WIN_FEAT', ' &#187; Yeni eklenti takip penceresi (Alt-P)');
define('PLUGIN_COMP_FEAT', '&#187; Desteklenen dillerle uyumlu eklentiler');
define('SKIN_WIN_FEAT', '&#187; Hızlı kabuk değiştirme penceresi');
define('SKINS_CHAT_FEAT', '&#187; Sohbet pencerelerinde kabuk desteği');
define('WIN_BOTTOM_FEAT', '&#187; Boyutlandırılabilir sohbet penceresi');
define('NEW_USER_GROUP_FEAT', '&#187; Yeni bir kişiyi istediğiniz gruba ekleyebilme özelliği');
define('CHAT_WIN_COLOR_FEAT', '&#187; Sohbet ettiğiniz kişinin durumu değiştiğinde pencerenin üstünde değişen renkler görebilme, ( yeşil:uygun, gri:çevrimdışı, vb.)');
define('VERSION_ALERT_FEAT', '&#187; Yeni bir aMSN sürümünü bildiren pencere özelliği');
define('DOWN_RELEASE_FEAT', '&#187; Yeni sürümü doğrudan aMSN üzerinden indirebilme');
define('AUTO_UPDATE_FEAT', '&#187; Dil ve eklentileri doğrudan güncelleyebilme');
define('DEL_USER_GUI_FEAT', '&#187; Kişi silme işlemi için yeni arayüz (silerken aynı zamanda engelleyebilme)');
define('USER_NOTES_FEAT', '&#187; Herbir kişi için notlar ekleyebilme (XML)');
define('MSN_MOBILE_FEAT', '&#187; MSN Mobile desteği');
define('TABBED_WIN_FEAT', '&#187; Sekmeli Penceler ile sohbetleri gruplayabilme');
define('STATUS_APPEAR_FEAT', '&#187; Kullanıcı durumu bir çerçeve içerisindedir, böylece listeyi kaydırırken durum görünümü kaybolmaz');
define('ALERT_PICTURE_FEAT', '&#187; Olay bildirimlerinde resim gösterme (MSN 7\'de olduğu gibi)');
define('HISTORY_STATS_FEAT', '&#187; Geçmiş istatistikleri (kayıtlar ile)');
define('LOGIN_STATUS_FEAT', '&#187; Artık giriş durumunuzu istediğiniz her şekilde seçebilirsiniz (önceden sadece çevrimdışı ya da görünmez olarak girilebiliyordu)');
define('TIMESTAMPING_FEAT', '&#187; Zaman bildirimi');
define('MORE_FEAT', 'Hepsi bu kadar değil! <a href="plugins.php">Eklentiler</a> ile birçok özelliği aMSN\'ye ekleyebilir  ya da maceracı olarak, <a href="skins.php">Kabuklar</a> ile aMSN görünümünü tamamiyle değiştirebilirsiniz!');
//features.php definitions END

//skins.php definitions START
define('LOVES_CUSTOM', '<strong>aMSN özelleştirilmeyi sever!</strong>');
define('SKIN_DESC', ',bunu yapabilmenin bir yolu da "kabuklar"dır. Kabuk aMSN\'in görünümü tamamiyle değiştirir . Burada aMSN ve katılımcılarının geliştirdiği kabukları indirebilirsiniz.');
define('INSTALL_SKIN', 'Bir kabuğu nasıl kurabileceğinizi <a href="http://www.amsn-project.net/wiki/Installing_Plugins_and_Skins">kabuk ve eklenti kurma rehberi</a>ne bakarak öğrenebilirsiniz.');
define('SUBMIT_SKIN', 'Eğer kendi geliştirdiğiniz bir kabuğun burada yayınlanmasını isterseniz, lütfen <a href="http://www.amsn-project.net/wiki/Dev:Sumbitting_Plugins_and_Skins">kabuk gönderme rehberi</a>ne bakınız.');
define('NO_SKIN', 'Gösterilecek bir kabuk bulunamadı.');
define('CREATEDBY_SKIN', 'Geliştiren:');
define('VERSION_SKIN', 'Sürüm:');
define('SCREENSHOTS_SKIN', 'Ekran Görüntüsü');
define('NOSCREEN_SKIN', 'Ekran Görüntüsü Yok');
define('DOWN_SKIN', 'Bu kabuğu İndir');
define('DOWN_SOON_SKIN', 'İndirme çok yakında!');
define('BACK_TOP_SKIN', 'Başa dön');
//skins.php definitions END

//plugins.php definitions START
define('FULL_FEATURES', 'aMSN özelliklerle doludur');
define('PLUGIN_DESC', ', fakat kullanılabilirliğini daha da artırabilirsiniz, eklentileri kurarak daha çok özellik edinebilirsiniz. Eklentiler adı üstünde olduğu gibi aMSN\'ye "eklenirler" ve ona yeni özellikler sağlarlar. Burada aMSN ve katılımcılarının geliştirdiği eklentileri indirebilirsiniz. Eklentiyi indirmeden önce mutlaka gereken aMSN sürümüne ("gereksinimler"e bakınız) ve doğru İşletim Sitemine sahip olduğunuzdan emin olunuz("İşletim Sistemi"ne bakınız).');
define('INSTALL_PLUGIN', 'Bir eklentiyi nasıl kurabileceğinizi <a href="http://www.amsn-project.net/wiki/Installing_Plugins_and_Skins">kabuk ve eklenti kurma rehberi</a>ne bakarak öğrenebilirsiniz.');
define('SUBMIT_PLUGIN', 'Eğer kendi geliştirdiğiniz bir eklentinin burada yayınlanmasını isterseniz, lütfen <a href="http://www.amsn-project.net/wiki/Dev:Sumbitting_Plugins_and_Skins">eklenti gönderme rehberi</a>ne bakınız.');
define('NO_PLUGINS', 'Gösterilecek bir eklenti bulunamadı.');
define('CREATEDBY_PLUGIN', 'Geliştiren:');
define('VERSION_PLUGIN', 'Sürüm:');
define('PLATFORM_PLUGIN', 'İşletim Sistemi:');
define('REQUIRES_PLUGIN', 'Gereksinimler: ');
define('SCREENSHOTS_PLUGIN', 'Ekran Görüntüleri');
define('NOSCREEN_PLUGIN', 'Ekran Görüntüsü Yok');
define('DOWN_PLUGIN', 'Bu eklentiyi İndir');
define('DOWN_SOON_PLUGIN', 'İndirme çok yakında!');
define('BACK_TOP_PLUGIN', 'Başa dön');
//plugins.php definitions END

//screenshots.php definitions START
define('NOSCREEN_SCREEN', 'Gösterilebilecek bir ekran görüntüsü bulunamadı.');
define('NOEXIST_SCREEN', 'Seçilen ekran görüntüsü bulunamadı. Silinmiş yada taşınmış olabilir.');
//screeenshots.php definitions END

//docs.php definitions START
define('AMSN_DOCS', 'aMSN Belgeleri');
define('LINKS_DOCS', 'aMSN Belgeleri için bağlantılar');
define('LINK_FAQ', 'SSS(Sıkça Sorulan Sorular)');
define('LINK_USER_WIKI', 'Kullanıcı için VIKI');
//docs.php definitions END

//developer.php definitions START
define('AMSN_DEV_TEAM', 'Amsn Geliştirme Ekibi');
define('DEV_DESC', 'Aşağıdaki bağlantıda şu anda ve geçmişte aMSN\'yi geliştiren insanların bir listesi bulunmaktadır.');
define('CURRENT_DEVS_DEV', 'Şimdiki Geliştiriciler');
define('PLEASE_HELP', 'Lütfen Destek');
define('HELP_DESC', 'Bu projeye katılmak isterseniz, lütfen aşağıdaki  bağlantıda verilen foruma bir mesaj bırakınız: ');
define('DONATION_DESC', 'aMSN projesine bağışta bulunmak isterseniz, aşağıdaki bağlantıda ne yapmanız gerektiğini ayrıntılı olarak bulabilirsiniz: ');
define('DONATIONS_DEV','Bağış Yap');
define('AMSN_BUG_REPORT', 'aMSN Hata Raporları');
define('BUGS_DESC', 'aMSN kullanırken bir hatayla karşılaşırsanız, lütfen hata oluştuğu andaki ayrıntıları ve mümkün olan yığın izini aşağıda verilen foruma gönderiniz. Bununla birlikte hata ve oluştuğu çevre hakkında sorularınızı bekliyoruz.');
define('REPORT_BUG', 'Hata Bildir');
define('PREV_BUG_REPORT', 'Önceki Hata Raporları');
define('AMSN_SVN', 'aMSN SVN');
define('SVN_DESC', 'Eğer AMSN\'in gidişatını yakından takip etmek istiyorsanız, En güncel geliştirme sürümünü doğrudan sourceforge SVN(Geliştirme Sürümü)\'den indirebilirsiniz. SVN daha önceki sürümlerdeki hataların düzeltmelerini içerir. Diğer taraftan, bu sürüm, ana sürümler kadar kararlı olmayabilir.');
define('BROWSE_SVN', 'SVN Deposunu Yükle');
define('SVN_HOWTO', 'SVN sürümü Kurulum Talimatları ');
define('AMSN_TRANSLATE', 'aMSN Çevirileri');
define('TRANSLATE_DESC', 'aMSN için bir çeviri göndermek isterseniz, şu sayfayı ziyaret ediniz: ');
//developer.php definitions END

//current-developer.php definitions START
define('CURRENT_DEVS', 'Şimdiki Geliştiriciler :');
define('ROLE_DEV', 'Görevi: ');
define('ADMIN_DEV', 'Yönetici');
define('DEVELOPER_DEV', 'Geliştirici');
define('MANAGER_DEV', 'Proje Yöneticisi');
define('INTER_DEV', 'Uluslararasılaştırma');
define('LOCATION_DEV', 'Bölge: ');
define('IRC_DEV', 'IRC Takma ismi: ');
define('WEB_SITE', 'Ağ sitesi');
define('BLOG_DEV', 'Blog');
define('GAMES_PLUG_DEV', 'Oyunlar Eklentisi Sağlayıcısı');
define('RETIRED_WEB_DEV', 'Emekli ağ sayfası geliştiricisi');
define('FARSIGHT_DEV', ' Farsight Proje Yöneticisi');
define('GRAPHICS_DEV', 'Grafiker ');
define('SKIN_DEV', ' Kabuk Tasarımcısı ');
define('WEB_DEV', ' Ağ Tasarımcısı');
define('UID_DEV', ' Arayüz Tasarımcısı ');
define('GRAPHART_DEV', ' Grafik sanatçısı');
define('TESTER_DEV', ' Deneyen');
define('CONTRIBUTORS_DEV', 'Deneyenler ve katılımcılar : ');
define('CODER_DEV', 'Kodlayıcı');
define('PACKAGER_DEV', 'Paketleyici');
define('AMSN_STARTED_DEV', 'aMSN\'yi başlatanlar: ');
define('CCMSN_DEV', 'CCMSN\in esas yazarı (aMSN, CCMSN\'den türetilmiştir)');
define('RETIRED_DEV', 'Emekli Geliştirici');
define('PEOPLE_HELPED_DEV', 'Yol üzerinde yardımcı olanlar :');
define('PHP_CODER_DEV', 'PHP Kodlayıcısı');
define('DATABASER_DEV', 'Veritabanı Geliştirici');
define('RETIRED_PHP_DEV', 'PHP Emekli site kodlayıcısı');
define('PLUGIN_MANAGER_DEV', 'Eklenti yöneticisi ');
define('AMSN_PLUS_DEV', ' aMSN Plus Geliştiricisi');
define('WIN_MAIN_DEV', ' Win Sağlayıcısı ');
define('MAC_PORTER_DEV', 'Mac Bağlamcısı ');
define('MAINTAINER_DEV', ' Sağlayıcı ');
//current-developer.php definitions end

//donatios.php definitions START
define('AMSN_DONATIONS_TITLE', 'aMSN Bağışları:');
define('DONATION_DESC1', 'Bazen kullanıcılar geliştiricilere başarılı bir projede harcadıkları zaman ve emek için teşekkür etmek isterler.  Bu nedenle, özgün geliştiricilere bağışta bulunabileceğiniz özel bir bölüm hazırladık.');
define('DONATION_DESC2', 'Bir bütün olarak aMSN, bağışları kabul etmemektedir, ancak aMSN geliştirme takımından özgün bir üyeye teşekkür etmek isterseniz size aşağıdaki bağlantıları sunmaktayız, bunlarla yapmak istediğinizi yapabilirsiniz:');
define('DONATE_TO', 'Bağış Yap: ');
define('BACK_TO_DEV', 'Geliştirme sayfasına geri dön');
//donations.php definitions END

//translations.php definitions START
define('TRANSLATION_TITLE', 'Posta listemize katılın!!');
define('MAIL_LIST_TRANS', 'Bize yardım etmek isteyanler için<a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">amsn-dil
posta listesimiz</a> bulunmaktadır.');
define('JOIN_TRANS', '<a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">Buraya</a>tıklayarak katılabilirsiniz.');
define('NEW_SENTENCES_TRANS', 'Yeni cümleler için çeviri istekleri buraya gönderilecektir, böylece herhengibiri anında cevap vererek istenen çeviriyi bize gönderecektir.');
define('READ_THIS_TRANS', '<b>Çevrilmemiş bölümleri nasıl çevireceğinizi öğrenmek için, lütfen öncelikle BU YAZIYI okuyunuz!</b><br/><br/>
TAKİP EDİLMESİ ZORUNLU KURALLAR:<br/></p>
<ul><li>Lütfen <a href="https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn/lang/LANG-HOWTO"><b>DIL-NASIL(LANG-HOWTO)</b></a> dosyasını okuyunuz.</li>');
define('READ_AGAIN_TRANS', '<li>DIL-NASIL(LANG-HOWTO) ı tekrar okuyunuz!</li>
<li>Güncellemek istediğiniz dilin bağlantısına tıklayınız (bu sayfanın altındaki)
<br/><br/>Açılan sayfada :<br/><br/></li>
<li>Eski dil dosyasını indirin ( açılan sayfada bulabileceksiniz )</li>
<li>Sayfanın en altında bulunan listedeki anahtar kelimeleri dil dosyasına ekleyin.</li>
<li>İngilizce açıklamaları çevirin</li>');
define('SEND_UPDATE_TRANS', '<li>Güncellediğiniz dosyayı <a href="mailto:amsn-translations@lists.sourceforge.net
">amsn-translations@lists.sourceforge.net</a>adresine gönderin</li>
<li>SADECE dil dosyaları kabul edilecektir. E-posta içerisinde bulunan HİÇBİR ayrı açıklama yada çeviri önerisi dikkate alınmayacaktır. E-postaya EKLENMİŞ, TAMAMIYLA çevrilmiş dil dosyasını(dosya adıda dahil, örneğin Türkçe için langtr) GÖNDERMELİSİNİZ. </li>
<li>Yukarıda vurgulandığı üzere, e-posta gövdesinde bulunan girdiler ÖNEMSENMEZ ve SİLİNİR.</li>
<li>Ayrıca
amsn-translations@lists.sourceforge.net  adresi dışında bir adresimize gönderilen çeviri dosyaları da ÖNEMSENMEZ ve SİLİNİR.</li></ul>');
define('CAN_HELP_TRANS', '<br/>Bazı cümleleri kendi dilinize çevirerek ya da yanlış çevrilmiş cümleleri düzelterek yardımcı olabilirsiniz.<br/><br/>');
define('BE_CAREFUL', 'Bazı cümlelerde görülen $1, $2... değişkenlerine dikkat ediniz.
Bu değişkenlerin cümle içindeki yerlerini değiştirebilirsiniz, ancak bu değişkenler <b>mutlaka</b> cümle içerisinde bulunmalıdırlar. Programın çalışması anında bu değişkenler farklı değerler almaktadırlar.<br/><br/><br/>');
define('NEW_LANG_TRANS', '
<b>Nasıl yeni bir dil eklenebilir?</b><br/><br/>
<ul><li>Diliniz içim bir kısa tanımlayıcı seçiniz (Örneğin, Türkçe için tr).</li>
<li>İngilizce dil dosyasını <a href="https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn/lang/langen">buradan</a>indirin.</li>
<li>langXX dosyasını XX yazan yere seçtiğiniz dil tanımlayıcısını yazarak yeniden adlandırınız.</li>
<li>Herbir satırın ilk kelimesi hariç (ki bu kelime bir anahtardır) dosyanın çevirisini yapın.</li>
<li>Yeni dosyayı<a href="mailto:amsn-translations@lists.sourceforge.net">amsn-translations@lists.sourceforge.net</a> adresine gönderin.</li>
</ul>');
//translations.php definitions END

//footer definition START
define('TRADEMARK_FOOT', 'Bu sitede bulunan tüm logolar ve ticari markalar kendi sahiplerinin mülkiyeti altındadır. Yorumlar ve yeni gönderiler gönderenlerinin sorumluluğundadır. Herşey  2002-2006 arasında aMSN ekibince hazırlanmıştır.');
//footer definition END
//side_panels START
define('HOSTED_BY','Oxilion tarafından yayınlanmaktadır');
define('LANGUAGE_SIDE','Diller');
define('POOLS_SIDE','Anketler');
define('POOL_SIDE_VOTE','Oy ver');
define('POOL_SIDE_RESULTS','Sonuçları Gör');
define('FORUMS_SIDE','Forumlar');
define('AMSN_FORUMS','aMSN Forumları');
define('RECENT_POSTS','Son Yazılar');
define('HELP_SIDE','Lütfen Destek');
define('HELP_BY_SIDE','aMSN geliştiricilerine bağış yaparak yardımda bulunun');
define('DONATION_PAGE_SIDE','aMSN bağış sayfası');
define('ADS_SIDE','Reklam');
define('LINKS_SIDE','Bağlantılar');
define('INSTALLER_LINKS','Otomatik kurulum programları<a href="http://www.autopackage.org/">Autopackage</a> ve <a href="http://nsis.sourceforge.net/">NSIS</a> ile yapılmıştır');
define('SF_LINK','SourceForge proje sayfası');
//END
//linux-downloads page START
define('GENERIC_INSTALLER','Genel Kurulum Dosyaları');
define('AMSN_INSTALLER_TCL84','aMSN Kurulum dosyası, Tcl/Tk&nbsp;8.4 için');
define('INDEPENT_INSTALLER84','Tcl/Tk&nbsp;8.4\'e <strong>sahip</strong> olanlar için dağıtım bağımsız kurulum dosyası');
define('AMSN_INSTALLER_TCL85','aMSN Kurulum dosyası Tcl/Tk&nbsp;8.5');
define('INDEPENT_INSTALLER85','Tcl/Tk&nbsp;8.5(<strong>son sürüm</strong>)\'e <strong>sahip</strong> olanlar için dağıtım bağımsız kurulum dosyası');
define('CREATED_WITH_AUTO','Bu genel kurulum dosyaları <a href="http://www.autopackage.org/">Autopackage</a> kullanılarak hazırlanmıştır.
      Bu dağıtımdan bağımsız ve bir kurucu içeren paketlerin oluşturulmasını sağlayan yeni Linux teknolojisidir. <a href="http://www.autopackage.org/gallery.html">Bu program kullanıcı dostu bir arayüze sahiptir. Kendiniz görün!</a>.');
define('PLEASE_FOLLOW','Paketleri kurmak için lütfen talimatları takip ediniz.');
define('DISTRO_INC_AMSN','aMSN\'yi İçeren Dağıtımlar');
define('DISTRO_DESC_1','Aşağıda bulunan dağıtımlar kendi paket depolarında aMSN\'yi bulundurmaktadırlar.
      Bu siteden bir indirme işlemi yapmadan, kendi paket yöneticinizi kullanarak aMSN\'yi kurabilirsiniz.');
define('DISTRO_DESC_2',' Bununla birlikte, bazı dağıtımlar henüz son sürümü desteklemiyor olabilirler.
       Bu nedenle <a href="#AP">aMSN Kurulum dosyası</a>\'ını kullanmanızı tavsiye ederiz');
define('OTHERWAY_TARBALL','Eğer bu yollar işe yaramazsa, aMSN\'yi kurmanın bir diğer yolu <a href="#tarball">kaynak arşivi</a>\'ni kullanmaktır.');
define('SOURCE_DOWNLOADS','Kaynak Kodu İndirmeleri');
define('AMSN_SOURCE','aMSN Kaynak Kodu');
define('BUILD_OWN_DISTRO','Kendi dağıtımınız için ikili dosyaları inşa edebileceğiniz Kaynak pakedi.');
define('SOURCE_DESC_1','Kaynak pakedini kullanarak kendi Linux dağıtımınız için ikili dosyaları inşa edebilirsiniz.
      Bununla birlikte, kaynak pakedinden RPM ya da DEB paketlerini, <span class="command">make rpm</span> ya da <span class="command">make deb</span> komutlarını kullanarak oluşturabilir ve böylece kendi dağıtımınız için özelleştirebilirsiniz.');
define('SOURCE_DESC_2','Lütfen <a href="http://amsn-project.net/wiki/Installing_Tarball">paket kurulum talimatlarını</a> takip ediniz.');
define('LATEST_DEV_TITLE','En son Geliştirme sürümü ( Son SVN Sürümü)');
define('SVN_SNAPSHOT','Son SVN Sürümü');
define('LATEST_DEV_SVN','En son geliştirme sürümü (Son SVN Sürümü');
define('LATEST_DEV_DESC','Geliştirme sürümümüzü denemek isteyebilirsiniz. Ancak, bu bir geliştirme sürümü olduğundan, resmi sürümlerden çok daha fazla hata içerebilir ve zaman zaman tamamiyle çökebilir. <a href="http://www.amsn-project.net/wiki/Installing_SVN">Viki sayfası</a>nda geliştirme sürümünü nasıl kurabileceğinizi ayrıntılı olarak bulabilirsiniz');
//linux-downloads page END
//pool_results
define('POOL_NOT_EXIST','Seçilen anket bulunamadı. Kaldırılmış olabilir.');
define('POOLS_VOTES','Oylar');
define('TOTAL_NUMBER_VOTES','Toplam oy sayısı');
define('POOL_TO_MAIN','Anasayfaya Geri Dön');
//pool_result END
?>
