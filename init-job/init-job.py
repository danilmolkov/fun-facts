import redis

def read_file_and_put_to_redis(file_path, redis_host='localhost', redis_port=6379, list_name='fun-facts'):
    # Connect to Redis
    r = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)

    r.delete(list_name)

    # Open the file and read lines
    with open(file_path, 'r') as file:
        for line in file:
            # Remove newline characters
            line = line.strip()
            print(f"Add fact: {line}")
            # Put the line into the Redis list
            r.rpush(list_name, line)
            r.rpush
    file.close()
    r.close()

    print("File contents have been added to Redis list:", list_name)

def add_key_value_from_file(file_path, redis_host='localhost', redis_port=6379):
    # Connect to Redis
    r = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)
    counter = 0
    with open(file_path, 'r') as file:
        for line in file:
            # Remove newline characters
            line = line.strip()
            print(f"Add fact: {counter}:{line}")
            # Put the line as key value
            r.set(counter, line)
            counter+=1
    print("File contents have been added to Redis list:", list_name)
    file.close()
    r.close()





if __name__ == "__main__":
    # Fill up redis db
    redis_host = 'localhost'
    redis_port = 6379
    list_name = 'fun-facts'
    file_path = "fun-facts.txt"  # Path to your text file
    read_file_and_put_to_redis(file_path, redis_host, redis_port, list_name)
    add_key_value_from_file(file_path, redis_host, redis_port)