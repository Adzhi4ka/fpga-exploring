# Светофор
## Описание файлов
* rtl/traffic_lights.sv   - реализация модуля
* tb/traffic_lights.sv - тесты для модуля
* tb/make.do          - файл со скриптом для запуска тестов
## Описание модуля
Представляет из себя конечный автомат.   
Состояние можно разделить на 2 группы: рабочие и нерабочие
* OFF - выключен (нерабочее)
* YELLOW_BLINK - режим настройки, для внешнего пользователя моргание желтым (нерабочее)
* Рабочие состояния

timer - 16 битный счетчик для времени пребывания автомата в "рабочем состоянии"
blink_cnt - 16 битный счетчик для времени между "морганием" зеленого или желтого
## Тесты
Пока просто проверяется работоспособность модуля и соответствие таймингам свечения сигналов
