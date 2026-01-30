# Gigily Themes - Python Showcase
from dataclasses import dataclass
from typing import Optional, List, Dict
from enum import Enum
import asyncio

class UserRole(Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

@dataclass
class User:
    """Represents a user in the system."""
    id: int
    name: str
    email: str
    role: UserRole
    active: bool = True

class UserService:
    """Service for managing user operations."""

    API_URL = "https://api.example.com"
    MAX_RETRIES = 3

    def __init__(self, api_key: str):
        self._api_key = api_key
        self._cache: Dict[int, User] = {}

    async def fetch_user(self, user_id: int) -> Optional[User]:
        """Fetch a user by ID with caching."""
        if user_id in self._cache:
            return self._cache[user_id]

        try:
            # Simulated API call
            user = User(
                id=user_id,
                name="John Doe",
                email="john@example.com",
                role=UserRole.USER
            )
            self._cache[user_id] = user
            return user
        except Exception as e:
            print(f"Error fetching user {user_id}: {e}")
            return None

    def get_admin_users(self, users: List[User]) -> List[User]:
        """Filter and return only admin users."""
        return [u for u in users if u.role == UserRole.ADMIN and u.active]

# Decorator example
def log_calls(func):
    """Decorator to log function calls."""
    def wrapper(*args, **kwargs):
        print(f"Calling {func.__name__}")
        result = func(*args, **kwargs)
        print(f"Finished {func.__name__}")
        return result
    return wrapper

@log_calls
def calculate_stats(numbers: List[int]) -> Dict[str, float]:
    """Calculate basic statistics."""
    if not numbers:
        return {"mean": 0, "total": 0}

    total = sum(numbers)
    mean = total / len(numbers)

    return {
        "mean": mean,
        "total": total,
        "count": len(numbers)
    }

# Main execution
if __name__ == "__main__":
    numbers = [10, 20, 30, 40, 50]
    stats = calculate_stats(numbers)
    print(f"Statistics: {stats}")
