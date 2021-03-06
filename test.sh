docker build -q -t ora .
docker run --rm --name ora -d -p 8080:8080 -e READ_MEMORY_API=http://localhost:8080/api/v1/debug/readByte ora

sleep 5

RESULT=`curl -s --header "Content-Type: application/json" \
  --request POST \
  --data '{"id":"abcd", "opcode":182,"state":{"a":51,"b":1,"c":15,"d":5,"e":15,"h":10,"l":2,"flags":{"sign":false,"zero":false,"auxCarry":false,"parity":false,"carry":true},"programCounter":1,"stackPointer":2,"cycles":1,"interruptsEnabled":true}}' \
  http://localhost:8080/api/v1/execute`
EXPECTED='{"id":"abcd", "opcode":182,"state":{"a":59,"b":1,"c":15,"d":5,"e":15,"h":10,"l":2,"flags":{"sign":false,"zero":false,"auxCarry":false,"parity":false,"carry":false},"programCounter":1,"stackPointer":2,"cycles":8,"interruptsEnabled":true}}'

docker kill ora

DIFF=`diff <(jq -S . <<< "$RESULT") <(jq -S . <<< "$EXPECTED")`

if [ $? -eq 0 ]; then
    echo -e "\e[32mORA Test Pass \e[0m"
    exit 0
else
    echo -e "\e[31mORA Test Fail  \e[0m"
    echo "$RESULT"
    echo "$DIFF"
    exit -1
fi