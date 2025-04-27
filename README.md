# Motion Estimation Accelerator

### Motion Estimation Hardware

### Scheduling

Tasarladığım accelerator tüm process elementlerini parallel çalıştırarak optimum sürede tüm SAD değerlerini hesaplamaya başlamaktadır.
Başlangıçta PE0 ilk search memory'deki satır ilk sütundan yani s(0,0)'dan (bellekte 0. adres) başlayarak işleme başlayarak ilk 16x16'lık resmin SAD değerini hesaplamaya başlamaktadır. Aynı anda PE1 s(1,2)'den başlayarak bir diğer kare için SAD değerini hesaplmaktadır. Bu iki processing elements aynı referance (current) memory'den okuduğu değeri kullanır.

İki clock periyodu sonrasında PE2 s(0,2)'den (bellekte 2. adres) işleme başlar. PE3 ise bir alt satırdan ve bir yandaki sütundan yani s(1,3)'den (bellekte 34. adres) işleme başlar. Bu iki 



### Timing

|Processing Element| Group |
|:----------------:|:-----:|
| PE0              | 0     |
| PE1              | 0     |
| PE2              | 1     |
| PE3              | 1     |
| PE4              | 2     |
| PE5              | 2     |
| PE6              | 3     |
| PE7              | 3     |

Her bir SAD hesaplaması 256 clock cycle sürülmektedir.
Bir satırda execution'a başlayan paralel çalışan 4 PE vardır, onun altındaki satırda aynı zamanda execution'a başlayan 4 PE daha vardır.
Toplamda 8 PE paralel çalışmaktadır.

Scheduling'e göre tüm processlerin işleme başlaması 6 clock cycle sürecektir.

Bir satırdaki başlayan processlerin bitmesi toplamda  2 x 256 = 512 clock cycle sürecektir.
Aynı anda bir alt satırdan başlayan processlerde tamamlanacaktır.
Yani iki satırdaki processlerin tamamının bitmesi bitmesi yaklaşık 512 clock cyle periyodu sürmektedir (system load süresi dışında). 
Toplamda 31x31'lik bir resim için 16 satır başlangıç satırı olacaktır. Her iki satır paralel olarak hesaplanmaktadır.

Bu yüzden toplam process süresi 512 * (16 / 2) + 6 = 4013 clock cycle olacaktır.