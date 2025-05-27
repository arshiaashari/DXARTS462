//LAB TASK 5 (Part I)

(
~server = Server.default.boot;
~iPhone = NetAddr("192.168.0.94", 9000);
~sensorValue = SensorValue('/accxyz', ~iPhone, ~server);
~sensorValue.value;
)
