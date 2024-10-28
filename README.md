# Сериализатор
## Описание файлов
* rtl/serializer.sv   - реализация модуля
* tb/serializer_tb.sv - тесты для модуля
* tb/make.do          - файл со скриптом для запуска тестов
## Описание модуля
Внутри используется память в размере 23 бит
* data_i_buff     - 16 битный буффер для входных данных
* data_mod_i_buff - 3 битный буффер для количества битов на сериализацию
* counter         - 4 битный счетчик для сериализации  
Как только приходит сигнал data_val_i, проверяю, что сериализатор не занят и data_mod_i входит в необходимые границы. Вывожу на busy_o и со следующего такта начинается сериализация.
## Тесты
Генерируются числа, которые в дальшейшем десериализируются
